using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SimpleMoxieSwitcher.Models;
using SimpleMoxieSwitcher.ViewModels;
using System;

namespace SimpleMoxieSwitcher.Views;

public sealed partial class MainWindow : Window
{
    public MainViewModel ViewModel { get; }

    public MainWindow()
    {
        InitializeComponent();
        ExtendsContentIntoTitleBar = true;
        SetTitleBar(null);

        ViewModel = App.Current.Services.GetService(typeof(MainViewModel)) as MainViewModel
            ?? throw new InvalidOperationException("MainViewModel not found in DI container");

        // Set window size
        var windowHandle = WinRT.Interop.WindowNative.GetWindowHandle(this);
        var windowId = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(windowHandle);
        var appWindow = Microsoft.UI.Windowing.AppWindow.GetFromWindowId(windowId);
        appWindow.Resize(new Windows.Graphics.SizeInt32(700, 600));
    }

    private async void OnStatusButtonClick(object sender, RoutedEventArgs e)
    {
        if (ViewModel.IsOnline)
        {
            // Show model selector
            var modelSelectorDialog = new ModelSelectorDialog();
            modelSelectorDialog.XamlRoot = Content.XamlRoot;
            await modelSelectorDialog.ShowAsync();
        }
    }

    private async void OnTileClick(object sender, RoutedEventArgs e)
    {
        if (sender is Button button && button.Tag is ITileItem tileItem)
        {
            await ViewModel.HandleTileClickAsync(tileItem);
        }
    }

    private async void OnItemClick(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is ITileItem tileItem)
        {
            await ViewModel.HandleTileClickAsync(tileItem);
        }
    }
}