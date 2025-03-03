import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_button_widget.dart';

class AppHeaderWidget extends StatelessWidget {
  const AppHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/logos/app_logo.png',
            height: 40,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.whatsapp),
                onPressed: () {
                  // TODO: Implement WhatsApp contact
                },
              ),
              const SizedBox(width: 8),
              // Ajout du widget de boutons d'authentification
              const AuthButtonWidget(),
            ],
          ),
        ],
      ),
    );
  }
}
