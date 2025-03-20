import 'dart:io';
import 'dart:math';
void main() 
{
  print("\x1B[33m"); 
  print("**************************************************");
  print("*            🎉 COMMITTEE MANAGEMENT 🎉          *");
  print("*             By FAIZAN - FA22-BSE-052           *");
  print("**************************************************\x1B[0m");

  print("\nPress Enter to start...");
  stdin.readLineSync();

  stdout.write("\x1B[36mEnter contribution per member (Rs.): \x1B[0m");
  int contribution = int.parse(stdin.readLineSync()!);

  stdout.write("\x1B[36mEnter total number of members: \x1B[0m");
  int totalMembers = int.parse(stdin.readLineSync()!);

  int totalAmount = contribution * totalMembers;
  List<String> members = [];

  print("\n\x1B[34mEnter member names:\x1B[0m");
  for (int i = 0; i < totalMembers; i++) {
    stdout.write("   ➤ Member ${i + 1}: ");
    members.add(stdin.readLineSync()!);
  }

  print("\n\x1B[32m✅ All members added! Now drawing winners...\x1B[0m\n");

  Random random = Random();
  List<String> availableWinners = List.from(members);

  while (availableWinners.isNotEmpty) {
    print("\x1B[35mPress Enter to draw a winner...\x1B[0m");
    stdin.readLineSync();

    int index = random.nextInt(availableWinners.length);
    String winner = availableWinners.removeAt(index);

    print("\n\x1B[33m**************************************************");
    print("*               🎊 CONGRATULATIONS! 🎊              *");
    print("*        🎖 WINNER: \x1B[31m$winner\x1B[33m 🎖           *");
    print("*        💰 PRIZE AMOUNT: Rs. ${totalAmount ~/ totalMembers} 💰  *");
    print("**************************************************\x1B[0m\n");
  }
  print("\x1B[32m🏆 All members have won once! Committee cycle completed. 🏆\x1B[0m");
  print("\n\x1B[36m💡 Thank you for using the Committee Management System! 💡\x1B[0m");
}
