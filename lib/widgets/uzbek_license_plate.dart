import 'package:flutter/material.dart';

class UzbekLicensePlateInput extends StatefulWidget {
  final TextEditingController regionController;   // 00
  final TextEditingController lettersController;  // A
  final TextEditingController numbersController;  // 123
  final TextEditingController suffixController;   // NN

  const UzbekLicensePlateInput({
    super.key, 
    required this.regionController,
    required this.lettersController,
    required this.numbersController,
    required this.suffixController,
  });

  @override
  State<UzbekLicensePlateInput> createState() => _UzbekLicensePlateInputState();
}

class _UzbekLicensePlateInputState extends State<UzbekLicensePlateInput> {
  final FocusNode _regionFocus = FocusNode();
  final FocusNode _lettersFocus = FocusNode();
  final FocusNode _numbersFocus = FocusNode();
  final FocusNode _suffixFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    // Стиль текста: ВСЕГДА черный, жирный, моноширинный
    const plateTextStyle = TextStyle(
      color: Colors.black, 
      fontSize: 22, 
      fontWeight: FontWeight.w900, 
      fontFamily: 'monospace'
    );

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white, // Всегда белый фон
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Row(
        children: [
          // 1. РЕГИОН (00)
          SizedBox(
            width: 50,
            child: TextField(
              controller: widget.regionController,
              focusNode: _regionFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: plateTextStyle,
              maxLength: 2,
              decoration: const InputDecoration(
                border: InputBorder.none, 
                counterText: "", 
                hintText: "00",
                hintStyle: TextStyle(color: Colors.grey),
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
              onChanged: (value) {
                if (value.length == 2) _lettersFocus.requestFocus();
              },
            ),
          ),
          
          Container(width: 3, height: 60, color: Colors.black), // Черта

          // 2. БУКВА (A)
          SizedBox(
            width: 40,
            child: TextField(
              controller: widget.lettersController,
              focusNode: _lettersFocus,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: plateTextStyle,
              maxLength: 1, // Одна буква
              decoration: const InputDecoration(
                border: InputBorder.none, 
                counterText: "",
                hintText: "A",
                hintStyle: TextStyle(color: Colors.grey),
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
              onChanged: (value) {
                if (value.length == 1) _numbersFocus.requestFocus();
                if (value.isEmpty) _regionFocus.requestFocus();
              },
            ),
          ),

          // 3. ЦИФРЫ (123)
          Expanded(
            child: TextField(
              controller: widget.numbersController,
              focusNode: _numbersFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: plateTextStyle.copyWith(fontSize: 26, letterSpacing: 3),
              maxLength: 3,
              decoration: const InputDecoration(
                border: InputBorder.none, 
                counterText: "",
                hintText: "123",
                hintStyle: TextStyle(color: Colors.grey),
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
              onChanged: (value) {
                if (value.length == 3) _suffixFocus.requestFocus();
                if (value.isEmpty) _lettersFocus.requestFocus();
              },
            ),
          ),

          // 4. ДВЕ БУКВЫ (NN)
          SizedBox(
            width: 55,
            child: TextField(
              controller: widget.suffixController,
              focusNode: _suffixFocus,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: plateTextStyle,
              maxLength: 2, // Две буквы
              decoration: const InputDecoration(
                border: InputBorder.none, 
                counterText: "",
                hintText: "NN",
                hintStyle: TextStyle(color: Colors.grey),
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
              onChanged: (value) {
                if (value.isEmpty) _numbersFocus.requestFocus();
              },
            ),
          ),

          // 5. ФЛАГ UZ
          Container(
            padding: const EdgeInsets.only(right: 8, left: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22, height: 14,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5)),
                  child: Column(
                    children: [
                      Expanded(child: Container(color: Colors.blue)),
                      Expanded(child: Container(color: Colors.white)),
                      Expanded(child: Container(color: Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text("UZ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16))
              ],
            ),
          )
        ],
      ),
    );
  }
}