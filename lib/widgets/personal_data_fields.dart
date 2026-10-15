import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/validators/validators.dart';
import 'custom_text_field.dart';

/// Campos de datos personales compartidos por el registro por correo, el
/// perfil pendiente de Google y «Mis datos». Así las reglas de validación y
/// los formatos son idénticos en todos los formularios.

/// Nombre y apellido: en una fila si hay espacio, en columna si no.
class NameFields extends StatelessWidget {
  const NameFields({
    super.key,
    required this.nombre,
    required this.apellido,
    this.enabled = true,
    this.autofocus = false,
    this.keyPrefix = 'register',
  });

  final TextEditingController nombre;
  final TextEditingController apellido;
  final bool enabled;
  final bool autofocus;

  /// Prefijo de las claves de prueba (`<prefijo>_nombre`, `<prefijo>_apellido`).
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final nombreField = CustomTextField(
          fieldKey: Key('${keyPrefix}_nombre'),
          label: 'Nombre',
          hint: 'Ej.: María José',
          icon: Icons.badge_outlined,
          controller: nombre,
          validator: Validators.firstName,
          maxLength: AppConstants.maxNameLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.givenName],
          enabled: enabled,
          autofocus: autofocus,
        );
        final apellidoField = CustomTextField(
          fieldKey: Key('${keyPrefix}_apellido'),
          label: 'Apellido',
          hint: 'Ej.: Pérez de la Cruz',
          icon: Icons.badge_outlined,
          controller: apellido,
          validator: Validators.lastName,
          maxLength: AppConstants.maxNameLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.familyName],
          enabled: enabled,
        );
        if (c.maxWidth < 420) {
          return Column(
            children: [nombreField, const SizedBox(height: 16), apellidoField],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: nombreField),
            const SizedBox(width: 12),
            Expanded(child: apellidoField),
          ],
        );
      },
    );
  }
}

/// DNI de exactamente ocho dígitos.
class DniField extends StatelessWidget {
  const DniField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.fieldKey = const Key('register_dni'),
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Key fieldKey;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      fieldKey: fieldKey,
      label: 'DNI',
      hint: '${AppConstants.dniLength} dígitos',
      icon: Icons.credit_card_outlined,
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(AppConstants.dniLength),
      ],
      validator: Validators.dni,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

/// Número de teléfono: obligatorio, solo dígitos y exactamente nueve.
///
/// Los formateadores impiden escribir o pegar letras, espacios o símbolos y
/// limitan la longitud; aun así [Validators.phone] valida el contenido (no se
/// confía solo en el teclado numérico).
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.fieldKey = const Key('register_telefono'),
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Key fieldKey;

  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(AppConstants.phoneLength),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      fieldKey: fieldKey,
      label: 'Número de teléfono',
      hint: '${AppConstants.phoneLength} dígitos',
      icon: Icons.phone_outlined,
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: formatters,
      validator: Validators.phone,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }
}

/// Fecha de nacimiento elegida con el selector, mostrada como dd/MM/yyyy.
class BirthDateField extends StatelessWidget {
  const BirthDateField({
    super.key,
    required this.controller,
    required this.value,
    required this.onPicked,
    this.enabled = true,
    this.fieldKey = const Key('register_fecha'),
  });

  final TextEditingController controller;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final bool enabled;
  final Key fieldKey;

  static final DateFormat format = DateFormat('dd/MM/yyyy');

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: value ?? DateTime(now.year - 18, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldHintText: 'dd/mm/aaaa',
      fieldLabelText: 'Fecha de nacimiento',
      errorFormatText: 'Usa el formato dd/mm/aaaa.',
      errorInvalidText: 'Ingresa una fecha válida y no futura.',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    controller.text = format.format(picked);
    onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      fieldKey: fieldKey,
      label: 'Fecha de nacimiento',
      hint: 'dd/mm/aaaa',
      icon: Icons.calendar_today_outlined,
      controller: controller,
      readOnly: true,
      onTap: () => _pick(context),
      validator: (_) => Validators.birthDate(value),
      suffix: IconButton(
        tooltip: 'Elegir fecha',
        icon: const Icon(Icons.edit_calendar_outlined, size: 20),
        onPressed: enabled ? () => _pick(context) : null,
      ),
      enabled: enabled,
    );
  }
}
