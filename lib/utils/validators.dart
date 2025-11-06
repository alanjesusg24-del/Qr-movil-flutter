class Validators {
  // Validar que un campo no esté vacío
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    return null;
  }

  // Validar email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  // Validar teléfono
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    final phoneRegex = RegExp(r'^\+?[\d\s\-()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Teléfono inválido';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos';
    }

    return null;
  }

  // Validar longitud mínima
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'Este campo'} debe tener al menos $minLength caracteres';
    }

    return null;
  }

  // Validar longitud máxima
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Este campo'} no puede exceder $maxLength caracteres';
    }

    return null;
  }

  // Validar que sea un número
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }

    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Este campo'} debe ser un número válido';
    }

    return null;
  }

  // Validar que sea un número entero
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }

    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'Este campo'} debe ser un número entero';
    }

    return null;
  }

  // Validar rango de números
  static String? range(
    String? value,
    double min,
    double max, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Este campo'} debe ser un número válido';
    }

    if (number < min || number > max) {
      return '${fieldName ?? 'Este campo'} debe estar entre $min y $max';
    }

    return null;
  }

  // Validar QR token
  static String? qrToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'El token QR es requerido';
    }

    final tokenRegex = RegExp(r'^[a-zA-Z0-9]{32}$');
    if (!tokenRegex.hasMatch(value)) {
      return 'Token QR inválido (debe tener 32 caracteres alfanuméricos)';
    }

    return null;
  }

  // Validar pickup token
  static String? pickupToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'El token de recolección es requerido';
    }

    final tokenRegex = RegExp(r'^[a-zA-Z0-9]{16}$');
    if (!tokenRegex.hasMatch(value)) {
      return 'Token inválido (debe tener 16 caracteres alfanuméricos)';
    }

    return null;
  }

  // Combinar múltiples validadores
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
