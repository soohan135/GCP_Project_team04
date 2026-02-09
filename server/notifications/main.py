import functions_framework
from firebase_admin import credentials, messaging, initialize_app, firestore
import google.cloud.firestore

# Firebase Admin SDK 초기화 (환경 변수 또는 기본 서비스 계정 사용)
try:
    initialize_app()
except ValueError:
    # 이미 초기화된 경우 무시
    pass

db = firestore.client()

@functions_framework.cloud_event
def send_estimate_notification(cloud_event):
    """
    Firestore 문서 생성 트리거: service_centers/{shopId}/receive_estimate/{docId}
    """
    path_parts = cloud_event["source"].split('/')
    # source format: projects/{project}/databases/(default)/documents/service_centers/{shopId}/receive_estimate/{docId}
    
    try:
        shop_id = path_parts[path_parts.index('service_centers') + 1]
    except (ValueError, IndexError):
        print("Error: Could not extract shopId from source path")
        return

    data = cloud_event.data["value"]["fields"]
    user_request = data.get("userRequest", {}).get("stringValue", "새로운 수리 요청이 있습니다.")
    damage_type = data.get("damageType", {}).get("stringValue", "차량 파손")

    # 1. 해당 정비소(shopId)를 담당하는 정비사들을 찾습니다.
    # users 컬렉션에서 serviceCenterId가 shop_id인 사용자들을 조회합니다.
    users_ref = db.collection("users")
    query = users_ref.where("serviceCenterId", "==", shop_id).where("role", "==", "mechanic")
    mechanics = query.stream()

    tokens = []
    for doc in mechanics:
        user_data = doc.to_dict()
        token = user_data.get("fcmToken")
        if token:
            tokens.append(token)

    if not tokens:
        print(f"No FCM tokens found for shop: {shop_id}")
        return

    # 2. FCM 메시지 구성
    message_title = f"🔔 새로운 견적 요청: {damage_type}"
    message_body = f"요청 사항: {user_request}"

    # 3. 멀티캐스트 메시지 전송 (여러 기기에 한 번에 전송)
    multicast_message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=message_title,
            body=message_body,
        ),
        tokens=tokens,
        data={
            "shopId": shop_id,
            "type": "new_estimate_request"
        }
    )

    response = messaging.send_multicast(multicast_message)
    print(f"Successfully sent {response.success_count} messages; failed {response.failure_count} messages.")

    if response.failure_count > 0:
        responses = response.responses
        for idx, resp in enumerate(responses):
            if not resp.success:
                print(f"Token {tokens[idx]} failed with error: {resp.exception}")
