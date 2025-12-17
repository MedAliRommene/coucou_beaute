"""Template tags pour gérer le genre des professionnels."""
from django import template

register = template.Library()


# Mapping des termes selon le genre
GENDER_TERMS = {
    'male': {
        'le_la': 'le',
        'professionnel': 'professionnel',
        'il_elle': 'il',
        'son_sa': 'son',
        'ce_cette': 'ce',
        'du_de_la': 'du',
        'au_a_la': 'au',
        'un_une': 'un',
        'expert': 'expert',
        'specialiste': 'spécialiste',
    },
    'female': {
        'le_la': 'la',
        'professionnel': 'professionnelle',
        'il_elle': 'elle',
        'son_sa': 'sa',
        'ce_cette': 'cette',
        'du_de_la': 'de la',
        'au_a_la': 'à la',
        'un_une': 'une',
        'expert': 'experte',
        'specialiste': 'spécialiste',
    },
}


@register.filter
def gender_term(gender, term):
    """
    Retourne le terme adapté au genre.
    
    Usage dans le template:
        {{ pro.extra.gender|gender_term:"professionnel" }}
        {{ pro.extra.gender|gender_term:"le_la" }}
    """
    gender_key = gender if gender in GENDER_TERMS else 'female'
    terms = GENDER_TERMS.get(gender_key, GENDER_TERMS['female'])
    return terms.get(term, term)


@register.filter
def gender_title(gender):
    """
    Retourne le titre adapté au genre.
    
    Usage: {{ pro.extra.gender|gender_title }}
    Retourne: "Professionnel" ou "Professionnelle"
    """
    if gender == 'male':
        return 'Professionnel'
    return 'Professionnelle'


@register.simple_tag
def pro_title(gender, capitalize=True):
    """
    Retourne le titre professionnel adapté.
    
    Usage: {% pro_title pro.extra.gender %}
    """
    title = gender_title(gender)
    return title.capitalize() if capitalize else title


@register.simple_tag
def gendered_text(gender, male_text, female_text):
    """
    Retourne le texte adapté au genre.
    
    Usage: {% gendered_text pro.extra.gender "le professionnel" "la professionnelle" %}
    """
    if gender == 'male':
        return male_text
    return female_text

