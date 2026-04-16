//
//  SurveyQuestion.swift
//  H3-CoqueGuide
//
//  Created by Santiago on 30/03/26.
//
//  NOTA DE LOCALIZACIÓN:
//  - `title` y `options` permanecen en español. Son los valores que se almacenan
//    en SwiftData y se usan en prompts de IA — no deben cambiar.
//  - `localizedTitle` y `localizedOptions` son las cadenas que se muestran al usuario.
//    Se calculan según AppLanguage.device en tiempo de ejecución.
//

import Foundation

enum SurveyStep: Int, CaseIterable {
    case gender
    case ageRange
    case plannedTime
    case attractionPreference
    case specificAttraction
    case language
    case coquePersonality

    // MARK: - Raw values (storage / AI prompts — always Spanish)

    var title: String {
        switch self {
        case .gender:               return "¿Cuál es tu género?"
        case .ageRange:             return "¿En qué rango de edad estás?"
        case .plannedTime:          return "Tiempo planeado para el recorrido"
        case .attractionPreference: return "Preferencias para atracciones"
        case .specificAttraction:   return "¿Vienes por alguna atracción en específico?"
        case .language:             return "Lenguaje para tu recorrido"
        case .coquePersonality:     return "¿Cómo prefieres la personalidad de guía \"Coque\"?"
        }
    }

    var options: [String] {
        switch self {
        case .gender:
            return ["Hombre", "Mujer", "Prefiero no decir"]
        case .ageRange:
            return ["18 o menos", "19 - 29", "30 - 50", "50 o más"]
        case .plannedTime:
            return ["1 hora o menos", "1 - 2 horas", "2 - 3 horas", "3 horas o más"]
        case .attractionPreference:
            return ["Interacción", "Galerías de objetos", "Shows", "Escuchar historia", "Todos", "Recomendado"]
        case .specificAttraction:
            return ["Galería historia", "Acería", "Reacción en cadena", "Restaurante", "Mirador", "Shows", "Paseo por hornos", "No"]
        case .language:
            return ["Español", "English", "Français", "Português", "Korean", "Arabic"]
        case .coquePersonality:
            return ["Formal", "Neutral", "Divertido", "Datos curiosos", "Para niños", "Historiador"]
        }
    }

    var columns: Int {
        switch self {
        case .gender:               return 1
        case .ageRange:             return 2
        case .plannedTime:          return 2
        case .attractionPreference: return 2
        case .specificAttraction:   return 2
        case .language:             return 2
        case .coquePersonality:     return 2
        }
    }

    // MARK: - Localized display values

    /// Título de la pregunta en el idioma del dispositivo.
    var localizedTitle: String {
        switch AppLanguage.device {
        case .spanish:    return title
        case .english:    return englishTitle
        case .french:     return frenchTitle
        case .portuguese: return portugueseTitle
        case .korean:     return koreanTitle
        case .arabic:     return arabicTitle
        }
    }

    /// Etiquetas de las opciones en el idioma del dispositivo.
    /// El orden coincide exactamente con `options` para poder indexarlos juntos.
    /// El paso `.language` siempre devuelve los nombres de idioma en su propio script.
    var localizedOptions: [String] {
        if self == .language { return options }
        switch AppLanguage.device {
        case .spanish:    return options
        case .english:    return englishOptions
        case .french:     return frenchOptions
        case .portuguese: return portugueseOptions
        case .korean:     return koreanOptions
        case .arabic:     return arabicOptions
        }
    }

    // MARK: - English

    private var englishTitle: String {
        switch self {
        case .gender:               return "What is your gender?"
        case .ageRange:             return "What is your age range?"
        case .plannedTime:          return "Planned time for the tour"
        case .attractionPreference: return "Attraction preferences"
        case .specificAttraction:   return "Are you visiting for a specific attraction?"
        case .language:             return "Language for your tour"
        case .coquePersonality:     return "How do you prefer Coque's guide personality?"
        }
    }

    private var englishOptions: [String] {
        switch self {
        case .gender:
            return ["Male", "Female", "Prefer not to say"]
        case .ageRange:
            return ["18 or under", "19 - 29", "30 - 50", "50 or over"]
        case .plannedTime:
            return ["1 hour or less", "1 - 2 hours", "2 - 3 hours", "3+ hours"]
        case .attractionPreference:
            return ["Interaction", "Object galleries", "Shows", "History stories", "All", "Recommended"]
        case .specificAttraction:
            return ["History gallery", "Steel mill", "Chain reaction", "Restaurant", "Viewpoint", "Shows", "Furnace walk", "None"]
        case .language:
            return options
        case .coquePersonality:
            return ["Formal", "Neutral", "Fun", "Fun facts", "For kids", "Historian"]
        }
    }

    // MARK: - French

    private var frenchTitle: String {
        switch self {
        case .gender:               return "Quel est votre genre ?"
        case .ageRange:             return "Dans quelle tranche d'âge êtes-vous ?"
        case .plannedTime:          return "Temps prévu pour la visite"
        case .attractionPreference: return "Préférences d'attractions"
        case .specificAttraction:   return "Venez-vous pour une attraction particulière ?"
        case .language:             return "Langue pour votre visite"
        case .coquePersonality:     return "Comment préférez-vous la personnalité du guide « Coque » ?"
        }
    }

    private var frenchOptions: [String] {
        switch self {
        case .gender:
            return ["Homme", "Femme", "Préfère ne pas dire"]
        case .ageRange:
            return ["18 ou moins", "19 - 29", "30 - 50", "50 ou plus"]
        case .plannedTime:
            return ["1 heure ou moins", "1 - 2 heures", "2 - 3 heures", "3+ heures"]
        case .attractionPreference:
            return ["Interaction", "Galeries d'objets", "Spectacles", "Histoire racontée", "Tout", "Recommandé"]
        case .specificAttraction:
            return ["Galerie d'histoire", "Aciérie", "Réaction en chaîne", "Restaurant", "Belvédère", "Spectacles", "Promenade des fours", "Non"]
        case .language:
            return options
        case .coquePersonality:
            return ["Formel", "Neutre", "Amusant", "Anecdotes", "Pour enfants", "Historien"]
        }
    }

    // MARK: - Portuguese

    private var portugueseTitle: String {
        switch self {
        case .gender:               return "Qual é o seu gênero?"
        case .ageRange:             return "Em qual faixa etária você está?"
        case .plannedTime:          return "Tempo planejado para o tour"
        case .attractionPreference: return "Preferências de atrações"
        case .specificAttraction:   return "Você vem por alguma atração específica?"
        case .language:             return "Idioma para o seu tour"
        case .coquePersonality:     return "Como você prefere a personalidade do guia \"Coque\"?"
        }
    }

    private var portugueseOptions: [String] {
        switch self {
        case .gender:
            return ["Homem", "Mulher", "Prefiro não dizer"]
        case .ageRange:
            return ["18 ou menos", "19 - 29", "30 - 50", "50 ou mais"]
        case .plannedTime:
            return ["1 hora ou menos", "1 - 2 horas", "2 - 3 horas", "3+ horas"]
        case .attractionPreference:
            return ["Interação", "Galerias de objetos", "Shows", "Ouvir história", "Todos", "Recomendado"]
        case .specificAttraction:
            return ["Galeria de história", "Aciaria", "Reação em cadeia", "Restaurante", "Mirante", "Shows", "Passeio pelos fornos", "Não"]
        case .language:
            return options
        case .coquePersonality:
            return ["Formal", "Neutro", "Divertido", "Curiosidades", "Para crianças", "Historiador"]
        }
    }

    // MARK: - Korean

    private var koreanTitle: String {
        switch self {
        case .gender:               return "성별이 어떻게 되세요?"
        case .ageRange:             return "연령대가 어떻게 되세요?"
        case .plannedTime:          return "투어 예상 시간"
        case .attractionPreference: return "관광지 선호도"
        case .specificAttraction:   return "특정 관광지를 목적으로 방문하셨나요?"
        case .language:             return "투어 언어"
        case .coquePersonality:     return "가이드 Coque의 스타일을 선택해 주세요"
        }
    }

    private var koreanOptions: [String] {
        switch self {
        case .gender:
            return ["남성", "여성", "밝히지 않겠습니다"]
        case .ageRange:
            return ["18세 이하", "19 - 29", "30 - 50", "50세 이상"]
        case .plannedTime:
            return ["1시간 이하", "1 - 2시간", "2 - 3시간", "3시간 이상"]
        case .attractionPreference:
            return ["체험", "물체 갤러리", "쇼", "역사 이야기", "전부", "추천"]
        case .specificAttraction:
            return ["역사 갤러리", "제철소", "연쇄 반응", "레스토랑", "전망대", "쇼", "용광로 투어", "없음"]
        case .language:
            return options
        case .coquePersonality:
            return ["격식체", "중립적", "재미있는", "흥미로운 사실", "어린이용", "역사가"]
        }
    }

    // MARK: - Arabic

    private var arabicTitle: String {
        switch self {
        case .gender:               return "ما هو جنسك؟"
        case .ageRange:             return "ما هي فئتك العمرية؟"
        case .plannedTime:          return "الوقت المخطط للجولة"
        case .attractionPreference: return "تفضيلات الأماكن السياحية"
        case .specificAttraction:   return "هل تزور لمكان معين؟"
        case .language:             return "لغة الجولة"
        case .coquePersonality:     return "كيف تفضل شخصية المرشد «Coque»؟"
        }
    }

    private var arabicOptions: [String] {
        switch self {
        case .gender:
            return ["ذكر", "أنثى", "أفضل عدم الإفصاح"]
        case .ageRange:
            return ["18 أو أقل", "19 - 29", "30 - 50", "50 أو أكثر"]
        case .plannedTime:
            return ["ساعة أو أقل", "1 - 2 ساعات", "2 - 3 ساعات", "3 ساعات أو أكثر"]
        case .attractionPreference:
            return ["تفاعل", "معارض المجسمات", "عروض", "الاستماع للتاريخ", "الكل", "موصى به"]
        case .specificAttraction:
            return ["معرض التاريخ", "مصنع الصلب", "تفاعل سلسلة", "مطعم", "نقطة مراقبة", "عروض", "جولة الأفران", "لا"]
        case .language:
            return options
        case .coquePersonality:
            return ["رسمي", "محايد", "ممتع", "معلومات شيقة", "للأطفال", "مؤرخ"]
        }
    }
}

enum SurveyScreen {
    case home
    case question
    case description
}
