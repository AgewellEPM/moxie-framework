using System.Windows;
using SimpleMoxieSwitcher.ViewModels;

namespace SimpleMoxieSwitcher.Views;

public partial class SetupWizardView : Window
{
    public SetupWizardView()
    {
        InitializeComponent();
        DataContext = new SetupWizardViewModel();

        // Subscribe to close commands
        if (DataContext is SetupWizardViewModel viewModel)
        {
            // Handle cancel/close events
            viewModel.PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(SetupWizardViewModel.CurrentStep) && viewModel.CurrentStep > 6)
                {
                    Close();
                }
            };
        }
    }
}
