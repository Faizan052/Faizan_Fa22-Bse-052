using System.Windows;

namespace UserRegistration
{
    public partial class RegistrationForm : Window
    {
        public RegistrationForm()
        {
            InitializeComponent();
        }

        private void Register_Click(object sender, RoutedEventArgs e)
        {
            string fullName = txtFullName.Text;
            string email = txtEmail.Text;
            string password = txtPassword.Password;
            string confirmPassword = txtConfirmPassword.Password;

            if (password == confirmPassword)
            {
                MessageBox.Show($"Registration Successful!\nName: {fullName}\nEmail: {email}", "Success");
            }
            else
            {
                MessageBox.Show("Passwords do not match!", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}
