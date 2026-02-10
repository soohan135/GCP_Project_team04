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

def predict_damage(image_path, user_id=None, car_model='unknown'):
    """
    외부 AI Cloud Run 서비스에 이미지를 전송하여 분석 결과를 받아옵니다.
    (인증 토큰 생성 로직 포함)
    """
    if not AI_SERVICE_URL or "YOUR_AI_SERVICE_URL_HERE" in AI_SERVICE_URL:
        print("Error: AI_SERVICE_URL environment variable is not set correctly.")
        raise ValueError("AI_SERVICE_URL not configured")

    print(f"Sending image to AI Service: {AI_SERVICE_URL}")
    
    # 1. 인증 토큰(ID Token) 생성
    # Cloud Run을 호출하기 위한 '출입증'을 만듭니다.
    auth_req = google.auth.transport.requests.Request()
    try:
        id_token = google.oauth2.id_token.fetch_id_token(auth_req, AI_SERVICE_URL)
    except Exception as e:
        print(f"Warning: Could not fetch ID token. Local emulation or missing permissions? Error: {e}")
        # 로컬 테스트나 인증이 필요 없는 경우를 위해 None으로 처리하거나 예외를 던질 수 있음
        # 여기서는 예외를 던져서 명확히 실패하게 함 (Cloud 환경 가정)
        raise e

    # 헤더에 토큰을 담습니다.
    headers = {
        "Authorization": f"Bearer {id_token}"
    }
    
    try:
        with open(image_path, 'rb') as img_file:
            # 2. 데이터 구성
            # 파일명과 MIME 타입(image/jpeg 등)을 명시적으로 지정
            mime_type = 'image/jpeg' if image_path.lower().endswith(('.jpg', '.jpeg')) else 'image/png'
            files = {'file': (os.path.basename(image_path), img_file, mime_type)}
            data = {'car_model': car_model}
            if user_id:
                data['user_id'] = user_id

            # 3. 요청 전송 (헤더 포함)
            # URL 끝에 /predict 추가 (중복 슬래시 방지)
            target_url = AI_SERVICE_URL.rstrip('/') + '/predict'
            
            response = requests.post(
                target_url, 
                files=files, 
                data=data,
                headers=headers
            )
            
        response.raise_for_status() 
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error calling AI service: {e}")
        if hasattr(e, 'response') and e.response is not None:
             print(f"Server Response: {e.response.text}")
        raise

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
        metadata = {} # Audit Log에서는 메타데이터 추출이 복잡하므로 생략하거나 별도 조회 필요
    else:
        # Case 2: Direct Storage Trigger (Legacy/Standard)
        print("Processing as Direct Storage event...")
        bucket_name = data.get("bucket")
        file_name = data.get("name")
        contentType = data.get("contentType", "")
        metadata = data.get("metadata", {}) # 메타데이터 추출

    print(f"Event ID: {event_id}")
    print(f"Event Type: {event_type}")
    print(f"Bucket: {bucket_name}")
    print(f"File: {file_name}")
    print(f"Created: {timeCreated}")
    print(f"Content Type: {contentType}")
    if metadata:
        print(f"Metadata: {metadata}")

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

    try:
        # 4. GCS에서 이미지 다운로드 및 메타데이터 조회
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        
        # 메타데이터를 확실하게 가져오기 위해 reload 호출
        blob.reload()
        
        # 메타데이터에서 차종 추출
        car_model = 'unknown'
        if blob.metadata:
            car_model = blob.metadata.get('carModel', 'unknown')
            
        print(f"Detected Car Model from Blob Metadata: {car_model}")
        
        # 이미지를 메모리(BytesIO)에 다운로드
        
        # 이미지를 메모리(BytesIO)에 다운로드
        from io import BytesIO
        image_data = BytesIO()
        blob.download_to_file(image_data)
        image_data.seek(0) # 파일 포인터를 처음으로 이동
        
        print(f"Downloaded {file_name} to memory")

        # 6. AI 추론 실행 (외부 서비스 호출)
        if not AI_SERVICE_URL or "YOUR_AI_SERVICE_URL_HERE" in AI_SERVICE_URL:
             raise ValueError("AI_SERVICE_URL not configured")
        
        # ID Token 생성
        auth_req = google.auth.transport.requests.Request()
        id_token = google.oauth2.id_token.fetch_id_token(auth_req, AI_SERVICE_URL)
        headers = {"Authorization": f"Bearer {id_token}"}
        
        # 요청 전송
        target_url = AI_SERVICE_URL.rstrip('/') + '/predict'
        
        mime_type = 'image/jpeg' if file_name.lower().endswith(('.jpg', '.jpeg')) else 'image/png'
        files = {'file': (file_basename, image_data, mime_type)}
        data = {'car_model': car_model, 'user_id': uid}
        
        print(f"Sending request to {target_url} with user_id={uid}, car_model={car_model}")
        
        response = requests.post(
            target_url,
            files=files,
            data=data,
            headers=headers
        )
        
        response.raise_for_status()
        prediction_result = response.json()
        
        # 원래 이미지 URL 추가
        download_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/crashed_car_picture%2F{file_basename}?alt=media"
        prediction_result['imageUrl'] = download_url
        
        # 7. 결과 로그 출력
        print(f"Analysis completed for user: {uid}")
        print(f"Prediction Result: {prediction_result}")

    except Exception as e:
        print(f"Error processing image: {e}")
        raise e


#dummy