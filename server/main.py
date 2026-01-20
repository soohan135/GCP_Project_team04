import logging
from io import BytesIO

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, HttpUrl
from PIL import Image
import requests

# --- 설정 ---
# TODO: 향후 실제 AI 모델 서비스 URL로 교체하거나 환경 변수에서 로드하세요.
# 예: AI_MODEL_ENDPOINT = "http://localhost:8001/v1/models/damage-detection"
AI_MODEL_ENDPOINT = None 

# 운영 환경에 적합한 로그 출력 설정
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="자동차 파손 분석 서비스",
    description="자동차 이미지를 처리하고 파손 예측 견적을 가져오는 API입니다.",
    version="1.0.0"
)

# --- 데이터 모델 ---
class AnalysisRequest(BaseModel):
    user_id: str
    image_url: HttpUrl  # Pydantic이 해당 문자열이 올바른 URL인지 자동으로 검증합니다.

class AnalysisResponse(BaseModel):
    status: str
    damage_part: str | None
    estimated_cost: int | None
    message: str

# --- 보조 함수 ---
def _mock_ai_inference(image: Image.Image) -> dict:
    """
    AI 모델의 응답을 시뮬레이션합니다.
    TODO: 이 로직을 실제 AI 모델 API 호출 또는 로컬 추론 코드로 교체하세요.
    """
    # 임시 로직 (테스트용)
    return {
        "part": "front_bumper",
        "cost": 350000
    }

# --- API 엔드포인트 ---
@app.get("/", tags=["Health"])
async def health_check():
    """서버 가동 여부를 확인합니다."""
    return {"status": "active", "service": "자동차 파손 분석 API"}

@app.post("/predict", response_model=AnalysisResponse, tags=["Analysis"])
async def analyze_damage(request: AnalysisRequest):
    """
    이미지 URL을 수신하고, 접근성을 검증한 후 AI 모델에 분석을 요청합니다.
    """
    logger.info(f"사용자 ID {request.user_id}로부터 분석 요청 수신")
    
    # 1. 이미지 가져오기 및 검증
    try:
        # 제공된 URL(예: Firebase Storage)에서 이미지를 가져옵니다.
        response = requests.get(str(request.image_url), timeout=10)
        response.raise_for_status()
        
        # 유효한 이미지 파일인지 확인합니다.
        image = Image.open(BytesIO(response.content))
        image.verify() # 파일 무결성 검증
        
        # 처리를 위해 다시 엽니다 (verify() 함수가 파일 포인터를 끝으로 이동시키기 때문)
        image = Image.open(BytesIO(response.content)) 
        
        logger.info(f"이미지 검증 성공. 크기: {image.size}, 포맷: {image.format}")

    except requests.exceptions.RequestException as e:
        logger.error(f"이미지 다운로드 실패: {e}")
        raise HTTPException(status_code=400, detail="제공된 URL에서 이미지를 가져오지 못했습니다.")
    except Exception as e:
        logger.error(f"유효하지 않은 이미지 데이터: {e}")
        raise HTTPException(status_code=400, detail="제공된 URL이 유효한 이미지를 가리키고 있지 않습니다.")

    # 2. AI 추론 (Inference)
    try:
        # 실제 상황에서는 여기서 AI 서버로 'image' 또는 'request.image_url'을 전송합니다.
        result = _mock_ai_inference(image)
        
        logger.info(f"분석 완료. 파손 부위: {result['part']}, 예상 비용: {result['cost']}")
        
        return AnalysisResponse(
            status="success",
            damage_part=result['part'],
            estimated_cost=result['cost'],
            message="성공적으로 분석되었습니다."
        )

    except Exception as e:
        logger.error(f"AI 처리 중 오류 발생: {e}")
        raise HTTPException(status_code=500, detail="AI 분석 중 내부 오류가 발생했습니다.")