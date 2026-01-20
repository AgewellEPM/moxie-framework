using System;
using System.Windows;
using System.Windows.Input;
using SimpleMoxieSwitcher.ViewModels;

namespace SimpleMoxieSwitcher
{
    public partial class MainWindow : Window
    {
        private ContentViewModel _viewModel;

        public MainWindow()
        {
            InitializeComponent();
            _viewModel = new ContentViewModel();
            DataContext = _viewModel;

            // Load initial data
            Loaded += async (s, e) => await _viewModel.InitializeAsync();
        }

        private void TitleBar_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ClickCount == 2)
            {
                WindowState = WindowState == WindowState.Maximized
                    ? WindowState.Normal
                    : WindowState.Maximized;
            }
            else
            {
                DragMove();
            }
        }

        private void MinimizeButton_Click(object sender, RoutedEventArgs e)
        {
            WindowState = WindowState.Minimized;
        }

        private void MaximizeButton_Click(object sender, RoutedEventArgs e)
        {
            WindowState = WindowState == WindowState.Maximized
                ? WindowState.Normal
                : WindowState.Maximized;
        }

        private void CloseButton_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }

        private void OnlineStatus_Click(object sender, MouseButtonEventArgs e)
        {
            if (_viewModel.IsOnline)
            {
                // Open Model Selector Dialog
                var modelSelectorWindow = new Views.ModelSelectorView();
                modelSelectorWindow.Owner = this;
                modelSelectorWindow.ShowDialog();
            }
        }
    }
}