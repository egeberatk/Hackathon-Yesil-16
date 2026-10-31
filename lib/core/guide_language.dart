/// Presentation-only wording; catalogue records are intentionally untouched.
abstract final class GuideLanguage {
  static String neutral(String value) {
    const replacements = {
      'Yetişkinin kullanacağı ': '',
      'yetişkinin kullanacağı ': '',
      'Kesme ve delme işlemlerini yalnızca yetişkin yapmalı.':
          'Kesme ve delme işlemleri için yardım al.',
      'Kesme ve delme işlemlerini yalnızca yetişkin yapsın.':
          'Kesme ve delme işlemleri için yardım al.',
      'Kesme işlemi yetişkin tarafından yapılmalı':
          'Kesme işlemi için yardım al',
      'Kesimi yalnızca yetişkin yapsın.': 'Kesme işlemi için yardım al.',
      'Delme işlemi yalnızca yetişkine aittir.': 'Delme işlemi için yardım al.',
      'Kesici aletleri yalnızca yetişkin kullansın.':
          'Kesici aletler için yardım al.',
      'Kesme işini yetişkin yapsın.': 'Kesme işlemi için yardım al.',
      'yetişkin gözetiminde': 'gözetim altında',
      'yetişkin yardımı': 'yardım',
    };
    for (final entry in replacements.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }
    return value;
  }
}
