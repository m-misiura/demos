"""
English-only language detector using lingua-py
Detects all languages, blocks everything except English
"""

from lingua import LanguageDetectorBuilder
import logging

logger = logging.getLogger(__name__)

# Detect ALL languages for comprehensive coverage
DETECTOR = LanguageDetectorBuilder.from_all_languages().build()


def english_only(text: str, **kwargs: dict) -> dict:
    """
    Blocks any text that is not in English.
    
    Args:
        text: Input text to analyze
        **kwargs: 
            - confidence_threshold (float): Minimum confidence to trust detection (default: 0.5)
    
    Returns:
        dict: Detection result if non-English or empty, otherwise {}
    """
    
    # Block empty text
    if not text or not text.strip():
        return {
            "start": 0,
            "end": 0,
            "text": "",
            "detection_type": "language_violation",
            "detection": "empty_text",
            "score": 1.0
        }
    
    # Detect language
    confidence_threshold = kwargs.get("confidence_threshold", 0.5)
    confidence_values = DETECTOR.compute_language_confidence_values(text)
    
    if not confidence_values:
        return {
            "start": 0,
            "end": len(text),
            "text": text[:200],
            "detection_type": "language_violation",
            "detection": "undetectable",
            "score": 1.0
        }
    
    # Get top detection
    top = confidence_values[0]
    lang_code = top.language.iso_code_639_1.name.lower()
    confidence = top.value
    
    logger.info(f"Detected: {top.language.name} ({lang_code}), confidence: {confidence:.2%}")
    
    # Check if English with sufficient confidence
    if lang_code == "en" and confidence >= confidence_threshold:
        return {}
    
    # Block: either non-English or low confidence
    return {
        "start": 0,
        "end": len(text),
        "text": text[:200],
        "detection_type": "language_violation",
        "detection": f"non_english_{lang_code}" if lang_code != "en" else "low_confidence",
        "score": confidence,
        "metadata": {
            "detected_language": top.language.name,
            "language_code": lang_code,
            "confidence": confidence
        }
    }
