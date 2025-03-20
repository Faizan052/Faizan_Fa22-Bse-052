import 'dart:io';

List<Map<String, String>> contacts = [];

void main() 
{
  while (true) {
    print("\n===== Contact Manager =====");
    print("1. Add Contact\n2. View Contacts\n3. Update Contact\n4. Delete Contact\n5. Exit");
    stdout.write("Choose an option: ");
    var choice = stdin.readLineSync();

    if (choice == '5') {
      print("Exiting Contact Manager. Goodbye!");
      break;
    }

    switch (choice) {
      case '1': addContact(); break;
      case '2': viewContacts(); break;
      case '3': updateContact(); break;
      case '4': deleteContact(); break;
      default: print("Invalid choice. Try again.");
    }
  }
}

void addContact() {
  stdout.write("Enter name: ");
  var name = stdin.readLineSync()?.trim() ?? '';
  stdout.write("Enter phone: ");
  var phone = stdin.readLineSync()?.trim() ?? '';
  stdout.write("Enter email: ");
  var email = stdin.readLineSync()?.trim() ?? '';

  if ([name, phone, email].any((e) => e.isEmpty)) {
    print("Invalid input. All fields required.");
    return;
  }

  contacts.add({"name": name, "phone": phone, "email": email});
  print("Contact added!");
}

void viewContacts() {
  if (contacts.isEmpty) {
    print("No contacts found.");
    return;
  }
  print("\n===== Contact List =====");
  contacts.forEach((c) => print("${c['name']} - ${c['phone']} - ${c['email']}"));
}

void updateContact() {
  stdout.write("Enter name to update: ");
  var name = stdin.readLineSync()?.trim() ?? '';
  var contact = contacts.firstWhere((c) => c['name'] == name, orElse: () => {});

  if (contact.isEmpty) {
    print("Contact not found.");
    return;
  }

  stdout.write("New phone (leave empty to keep): ");
  var newPhone = stdin.readLineSync()?.trim();
  stdout.write("New email (leave empty to keep): ");
  var newEmail = stdin.readLineSync()?.trim();

  if (newPhone != null && newPhone.isNotEmpty) contact['phone'] = newPhone;
  if (newEmail != null && newEmail.isNotEmpty) contact['email'] = newEmail;

  print("Contact updated!");
}

void deleteContact() {
  stdout.write("Enter name to delete: ");
  var name = stdin.readLineSync()?.trim() ?? '';
  contacts.removeWhere((c) => c['name'] == name);
  print("Contact deleted.");
}




