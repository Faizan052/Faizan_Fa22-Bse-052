using System;
class Program
{
    static void ChangeValue(ref int num)
    {
        num = 10; 
    }
    static void Main()
    {
        int myNumber = 5;
        ChangeValue(ref myNumber);  
        Console.WriteLine(myNumber); 
    }
}