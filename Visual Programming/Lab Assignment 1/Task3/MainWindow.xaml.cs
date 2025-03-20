using System.Windows;
using System.Windows.Controls;

namespace Task3
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            // Attach event handler for the button
            SubmitButton.Click += SubmitButton_Click;
        }

        private void SubmitButton_Click(object sender, RoutedEventArgs e)
        {
            // Retrieve values
            string name = NameInput.Text;
            string password = PasswordInput.Text;
            ComboBoxItem selectedRole = Role.SelectedItem as ComboBoxItem;
            string role = selectedRole != null ? selectedRole.Content.ToString() : "Not selected";

            ComboBoxItem selectedDegree = Degree.SelectedItem as ComboBoxItem;
            string degree = selectedDegree != null ? selectedDegree.Content.ToString() : "Not selected";

            // Display in MessageBox
            string message = $"Name: {name}\nPassword: {password}\nRole: {role}\nApplying Degree: {degree}";
            MessageBox.Show(message, "Student Info");
        }
    }
}
