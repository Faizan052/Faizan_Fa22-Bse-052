using System.Windows;
using System.Windows.Controls;

namespace WPFStyles
{
    public partial class Activity3 : Window
    {
        public Activity3()
        {
            InitializeComponent();
        }

        private void ApplyStyle_Click(object sender, RoutedEventArgs e)
        {
            textblock1.Style = (Style)Resources["TitleText"];
        }
    }
}
