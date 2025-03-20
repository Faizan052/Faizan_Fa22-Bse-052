using System;
class Program
{
    static void ChangeValue(int num)
    {
        num = 10; 
    }

    static void Main()
    {
        int myNumber = 5;
        ChangeValue(myNumber);  
        Console.WriteLine(myNumber);
    }
}