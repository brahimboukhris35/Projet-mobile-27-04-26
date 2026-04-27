import 'package:flutter/material.dart';

class ErrorStyles {
  // Style de bordure pour les champs en erreur
  static OutlineInputBorder errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Colors.red, width: 2),
  );
  
  // Style de bordure normal
  static OutlineInputBorder defaultBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
  );
  
  // Style de bordure focus
  static OutlineInputBorder focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Colors.lightBlue, width: 3),
  );
  
  // Style de bordure focus erreur
  static OutlineInputBorder focusedErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Colors.red, width: 3),
  );
  
  static OutlineInputBorder getBorder(bool hasError, {bool isFocused = false}) {
    if (hasError) {
      return isFocused ? focusedErrorBorder : errorBorder;
    } else {
      return isFocused ? focusedBorder : defaultBorder;
    }
  }
}