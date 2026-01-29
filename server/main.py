import functions_framework
from datetime import datetime
import re
import os
import json
import requests
from google.cloud import storage
import google.auth.transport.requests
import google.oauth2.id_token

# AI 서비스 URL (환경 변수에서 가져옴)
AI_SERVICE_URL = os.environ.get("AI_SERVICE_URL", "https://YOUR_AI_SERVICE_URL_HERE")

def parse_filename(filename):
    """
    파일명에서 사용자 UID를 추출합니다.
    형식: {uid}_{YYYYMMDD}.jpg
    예: user123_20240122.jpg -> user123
    """
    # 확장자 제거
    base_name = filename.rsplit('.', 1)[0]
    
    # 마지막 언더스코어(_)를 기준으로 분리 (날짜 부분 분리)
    parts = base_name.rsplit('_', 1)
    
    if len(parts) == 2:
        return parts[0]
    return None

def predict_damage(image_source):
    """
    외부 AI Cloud Run 서비스에 이미지를 전송하여 분석 결과를 받아옵니다.
    image_source: 파일 경로(str) 또는 파일 객체(FileStorage 등)
    """
    if not AI_SERVICE_URL or "YOUR_AI_SERVICE_URL_HERE" in AI_SERVICE_URL:
        print("Error: AI_SERVICE_URL environment variable is not set correctly.")
        raise ValueError("AI_SERVICE_URL not configured")

    print(f"Sending image to AI Service: {AI_SERVICE_URL}")
    
    # 1. 인증 토큰(ID Token) 생성
    auth_req = google.auth.transport.requests.Request()
    try:
        id_token = google.oauth2.id_token.fetch_id_token(auth_req, AI_SERVICE_URL)
    except Exception as e:
        print(f"Warning: Could not fetch ID token. Local emulation or missing permissions? Error: {e}")
        raise e

    headers = {
        "Authorization": f"Bearer {id_token}"
    }
    
    file_handle = None
    try:
        # 2. 데이터 구성 (경로 vs 스트림 분기 처리)
        files = {}
        if isinstance(image_source, str):
            # 문자열이면 파일 경로로 간주 (기존 로직)
            file_handle = open(image_source, 'rb')
            files = {'file': file_handle}
        else:
            # 파일 객체인 경우 (스트림 중계)
            # requests에 (filename, fileobj, content_type) 튜플 전달
            filename = getattr(image_source, 'filename', 'unknown.jpg')
            content_type = getattr(image_source, 'content_type', 'application/octet-stream')
            stream = getattr(image_source, 'stream', image_source)
            files = {'file': (filename, stream, content_type)}

        # 3. 요청 전송
        response = requests.post(
            AI_SERVICE_URL, 
            files=files, 
            data={'car_model': 'unknown'},
            headers=headers
        )
            
        response.raise_for_status() 
        return response.json()
        
    except requests.exceptions.RequestException as e:
        print(f"Error calling AI service: {e}")
        if hasattr(e, 'response') and e.response is not None:
             print(f"Server Response: {e.response.text}")
        raise
    finally:
        if file_handle:
            file_handle.close()

@functions_framework.cloud_event
def analyze_crashed_car(cloud_event):
    """
    Google Cloud Storage에 파일이 업로드될 때 트리거되는 Cloud Function
    Support both Direct Storage Triggers and Cloud Audit Log Triggers.
    """
    data = cloud_event.data
    
    event_id = cloud_event["id"]
    event_type = cloud_event["type"]
    timeCreated = data.get("timeCreated", datetime.now().isoformat())
    
    # Audit Log Trigger vs Direct Storage Trigger handling
    if "protoPayload" in data:
        # Case 1: Cloud Audit Log Trigger
        print("Processing as Cloud Audit Log event...")
        resource_name = data["protoPayload"]["resourceName"]
        # resource_name format: projects/_/buckets/{bucket}/objects/{name}
        match = re.search(r'projects/_/buckets/(.*?)/objects/(.*)', resource_name)
        if match:
            bucket_name = match.group(1)
            file_name = match.group(2)
        else:
            print(f"Error: Could not parse resourceName: {resource_name}")
            return
        # Audit logs don't typically carry contentType in the top level. 
        # We'll assume it's valid if it matched the path pattern, or fetch metadata if strictly needed.
        contentType = "image/unknown" 
    else:
        # Case 2: Direct Storage Trigger (Legacy/Standard)
        print("Processing as Direct Storage event...")
        bucket_name = data.get("bucket")
        file_name = data.get("name")
        contentType = data.get("contentType", "")

    print(f"Event ID: {event_id}")
    print(f"Event Type: {event_type}")
    print(f"Bucket: {bucket_name}")
    print(f"File: {file_name}")
    print(f"Created: {timeCreated}")
    print(f"Content Type: {contentType}")

    if not bucket_name or not file_name:
        print("Error: Bucket or Name not found in event data.")
        return

    # 1. 파일 경로 및 이름 검증 ('crashed_car_picture/' 폴더 내의 파일인지 확인)
    if not file_name.startswith("crashed_car_picture/"):
        print(f"Skipping file not in target folder: {file_name}")
        return

    # 2. 이미지 파일 검증
    is_image_type = contentType.startswith("image/")
    is_image_ext = file_name.lower().endswith(('.jpg', '.jpeg', '.png'))
    
    if not (is_image_type or is_image_ext):
        print(f"Skipping non-image file: {file_name} (Type: {contentType})")
        return

    # 3. 파일명에서 UID 추출
    # name은 'crashed_car_picture/user123_20240122.jpg' 형태
    file_basename = file_name.split('/')[-1]
    uid = parse_filename(file_basename)

    if not uid:
        print(f"Could not extract UID from filename: {file_basename}")
        return

    print(f"Detected UID: {uid}")

    storage_client = storage.Client()
    temp_local_path = f"/tmp/{file_basename}"

    try:
        # 4. GCS에서 이미지 다운로드
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        blob.download_to_filename(temp_local_path)
        print(f"Downloaded {file_name} to {temp_local_path}")

        # 5. AI 추론 실행 (외부 서비스 호출)
        prediction_result = predict_damage(temp_local_path)
        
        # 원래 이미지 URL 추가 (앱에서 표시용)
        # 참고: 이 URL은 공개 권한이 있거나, 앱에서 Signed URL을 생성해야 접근 가능할 수 있음
        download_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/crashed_car_picture%2F{file_basename}?alt=media"
        prediction_result['imageUrl'] = download_url
        
        # 6. 결과 로그 출력 (추후 Firestore 저장 로직으로 대체 필요)
        print(f"Analysis completed for user: {uid}")
        print(f"Prediction Result: {prediction_result}")

    except Exception as e:
        print(f"Error processing image: {e}")
        raise e
    finally:
        # 임시 파일 삭제
        if os.path.exists(temp_local_path):
            os.remove(temp_local_path)
            print(f"Removed temporary file: {temp_local_path}")

@functions_framework.http
def analyze_image_http(request):
    """
    Flutter 앱에서 직접 호출 가능한 HTTP 엔드포인트 (Proxy 역할).
    이미지를 받아서 AI 서비스로 전달하고 결과를 반환합니다.
    """
    # 1. CORS 설정 (앱에서 호출 허용)
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    if request.method != 'POST':
        return ('Only POST method is allowed', 405, headers)

    # 2. 파일 수신
    if 'file' not in request.files:
        return ('No file part in the request', 400, headers)
    
    file = request.files['file']
    if not file.filename:
        return ('No selected file', 400, headers)

    try:
        # 3. AI 서비스 호출 (스트림 중계)
        # 파일을 저장하지 않고 바로 predict_damage로 전달합니다.
        print(f"Streaming file {file.filename} to AI service...")
        prediction_result = predict_damage(file)
        
        print(f"AI Analysis Result: {prediction_result}")
        
        return (json.dumps(prediction_result), 200, headers)

    except Exception as e:
        print(f"Error in HTTP handler: {e}")
        return (f"Internal Server Error: {str(e)}", 500, headers)