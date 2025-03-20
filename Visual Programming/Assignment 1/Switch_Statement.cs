using System;
class Program
{
    static void Main()
    {
        int age, classifier = 0;
        Console.Write("Enter your age = ");
        age = int.Parse(Console.ReadLine());
        if (age >= 0 && age <= 10)
        {
            classifier = 1;
        }
        else if (age >= 11 && age <= 17)
        {
            classifier = 2;
        }
        else if (age >= 18 && age <= 40)
        {
            classifier = 3;
        }
        else if (age >= 41) 
        {
            classifier = 4;
        }
        switch (classifier)
        {
            case 1:
                Console.WriteLine("You are a child");
                break;
            case 2:
                Console.WriteLine("You are a teenager");
                break;
            case 3:
                Console.WriteLine("You are young");
                break;
            case 4:
                Console.WriteLine("You are an adult");
                break;
            default:
                Console.WriteLine("Invalid age entered.");
                break;
        }
    }
}