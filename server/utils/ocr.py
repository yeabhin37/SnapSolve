import re
from fastapi import HTTPException
from typing import List, Dict

# ------ Naver Clova OCR 파싱 함수 ------
def parse_clova_ocr_response(response_json: Dict) -> List[Dict]:
    """
    Naver Clova OCR 응답 JSON을 파싱하여 문제와 선지로 분리.
    한 이미지에 하나의 문제가 있다고 가정.
    """
    try:
        fields = response_json['images'][0]['fields']
        if not fields:
            return []

        # 인식된 모든 텍스트 추출
        texts = [field['inferText'] for field in fields]

        # 선지 번호(예: '①', '2')를 나타내는 텍스트 필드의 인덱스를 찾습니다.
        # 정규식: 문자열 전체가 원 문자 또는 한 자리 숫자로만 구성된 경우
        choice_marker_indices = [
            i for i, text in enumerate(texts)
            if re.fullmatch(r'[①②③④⑤]|\d', text)
        ]

        # 선지 번호를 찾지 못한 경우: 전체를 문제 지문으로 간주
        if not choice_marker_indices:
            # 선지를 찾지 못한 경우, 전체를 문제로 간주
            problem_text = " ".join(texts)
            return [{"problem": problem_text.strip(), "choices": []}]

        # 첫 번째 선지 번호가 시작되는 위치 파악
        first_choice_index_in_texts = choice_marker_indices[0]

        # 1. 문제 텍스트: 첫 선지 번호 이전까지의 모든 텍스트
        problem_text = " ".join(texts[:first_choice_index_in_texts]).strip()

        # 2. 선지 텍스트 파싱
        choices = []
        for i in range(len(choice_marker_indices)):
            start_index = choice_marker_indices[i]
            
            # 현재 선지의 끝 인덱스 결정 (다음 선지 시작 전까지, 마지막이면 끝까지)
            if i + 1 < len(choice_marker_indices):
                end_index = choice_marker_indices[i + 1]
            else:
                end_index = len(texts)
            
            choice_text = " ".join(texts[start_index:end_index]).strip()
            choices.append(choice_text)

        return [{"problem": problem_text, "choices": choices}]

    except (KeyError, IndexError) as e:
        # OCR 응답 구조가 예상과 다를 경우 예외 처리
        raise HTTPException(status_code=500, detail=f"OCR 응답 파싱 실패: {e}")
