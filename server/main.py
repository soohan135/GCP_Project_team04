import functions_framework
from datetime import datetime
import re

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

def mock_prediction(bucket, filename):
    """
    Mock AI 예측 함수 (Vertex AI 연동 전 단계)
    """
    download_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/crashed_car_picture%2F{filename}?alt=media"
    
    # 더미 데이터 반환
    return {
        "damage": "전면 범퍼 파손 (Scratched Bumper)",
        "estimatedPrice": "₩250,000 - ₩350,000",
        "recommendations": ["범퍼 도색", "범퍼 교환 불필요", "기타 흠집 제거"],
        "imageUrl": download_url,
        "confidence": "98.5%"
    }

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
            bucket = match.group(1)
            name = match.group(2)
        else:
            print(f"Error: Could not parse resourceName: {resource_name}")
            return
        # Audit logs don't typically carry contentType in the top level. 
        # We'll assume it's valid if it matched the path pattern, or fetch metadata if strictly needed.
        contentType = "image/unknown" 
    else:
        # Case 2: Direct Storage Trigger (Legacy/Standard)
        print("Processing as Direct Storage event...")
        bucket = data.get("bucket")
        name = data.get("name")
        contentType = data.get("contentType", "")

    print(f"Event ID: {event_id}")
    print(f"Event Type: {event_type}")
    print(f"Bucket: {bucket}")
    print(f"File: {name}")
    print(f"Created: {timeCreated}")
    print(f"Content Type: {contentType}")

    if not bucket or not name:
        print("Error: Bucket or Name not found in event data.")
        return

    # 1. 파일 경로 및 이름 검증 ('crashed_car_picture/' 폴더 내의 파일인지 확인)
    if not name.startswith("crashed_car_picture/"):
        print(f"Skipping file not in target folder: {name}")
        return

    # 2. 이미지 파일 검증 (Audit Log일 경우 contentType이 부정확할 수 있으므로 확장자 체크 추가)
    is_image_type = contentType.startswith("image/")
    is_image_ext = name.lower().endswith(('.jpg', '.jpeg', '.png'))
    
    if not (is_image_type or is_image_ext):
        print(f"Skipping non-image file: {name} (Type: {contentType})")
        return

    # 2. 파일명에서 UID 추출
    # name은 'crashed_car_picture/user123_20240122.jpg' 형태
    file_basename = name.split('/')[-1]
    uid = parse_filename(file_basename)

    if not uid:
        print(f"Could not extract UID from filename: {file_basename}")
        return

    print(f"Detected UID: {uid}")

    try:
        # 3. AI 추론 (Mock)
        # 실제 구현시에는 여기서 Vertex AI Endpoint를 호출합니다.
        prediction_result = mock_prediction(bucket, file_basename)
        
        # 4. 결과 로그 출력 (Firestore 저장 대신)
        print(f"Analysis completed for user: {uid}")
        print(f"Prediction Result: {prediction_result}")

    except Exception as e:
        print(f"Error processing image: {e}")
        # 필요시 에러 로깅을 강화하거나 재시도 로직 추가 가능
        raise e