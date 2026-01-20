using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Media.Imaging;
using SimpleMoxieSwitcher.Services;
using ZXing;
using ZXing.Common;
using ZXing.Windows.Compatibility;

namespace SimpleMoxieSwitcher.ViewModels;

public class SetupWizardViewModel : INotifyPropertyChanged
{
    private readonly DependencyInstallationService _installService;
    private readonly PINService _pinService;

    private int _currentStep;
    private bool _dockerInstalled;
    private bool _isChecking;
    private string _checkStatus = "";
    private bool _canContinue;

    // WiFi Settings
    private string _wifiSSID = "";
    private string _wifiPassword = "";
    private string _wifiEncryption = "WPA";

    // OpenMoxie Endpoint
    private string _moxieEndpoint = "http://localhost:8003/hive/endpoint/";

    // API Key
    private string _openAIKey = "";
    private bool _showingApiKey;

    // PIN Settings
    private string _createPIN = "";
    private string _confirmPIN = "";
    private string _parentEmail = "";

    // QR Code Images
    private BitmapSource? _wifiQRCode;
    private BitmapSource? _networkQRCode;

    public SetupWizardViewModel()
    {
        _installService = new DependencyInstallationService();
        _pinService = new PINService();

        // Load saved settings
        LoadSettings();

        // Initialize commands
        NextCommand = new RelayCommand(ExecuteNext, CanExecuteNext);
        PreviousCommand = new RelayCommand(ExecutePrevious, CanExecutePrevious);
        SkipCommand = new RelayCommand(ExecuteSkip);
        CancelCommand = new RelayCommand(ExecuteCancel);
        CheckDockerCommand = new RelayCommand(async () => await CheckDockerAsync());
        DownloadDockerCommand = new RelayCommand(DownloadDocker);
        AutoInstallDependenciesCommand = new RelayCommand(async () => await AutoInstallDependenciesAsync());

        // Subscribe to installation service events
        _installService.ProgressChanged += (s, progress) =>
        {
            CheckStatus = progress;
        };

        _installService.ErrorOccurred += (s, error) =>
        {
            CheckStatus = $"Error: {error}";
        };
    }

    // Properties
    public int CurrentStep
    {
        get => _currentStep;
        set
        {
            if (_currentStep != value)
            {
                _currentStep = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(CanGoPrevious));
                OnPropertyChanged(nameof(NextButtonText));

                // Update QR codes when entering those steps
                if (_currentStep == 3) GenerateWiFiQRCode();
                if (_currentStep == 4) GenerateNetworkQRCode();
                if (_currentStep == 5) AutoDetectOpenAIKey();
            }
        }
    }

    public bool DockerInstalled
    {
        get => _dockerInstalled;
        set { _dockerInstalled = value; OnPropertyChanged(); }
    }

    public bool IsChecking
    {
        get => _isChecking;
        set { _isChecking = value; OnPropertyChanged(); }
    }

    public string CheckStatus
    {
        get => _checkStatus;
        set { _checkStatus = value; OnPropertyChanged(); }
    }

    public bool CanContinue
    {
        get => _canContinue;
        set { _canContinue = value; OnPropertyChanged(); }
    }

    // WiFi Properties
    public string WiFiSSID
    {
        get => _wifiSSID;
        set
        {
            _wifiSSID = value;
            OnPropertyChanged();
            SaveWiFiCredentials();
            GenerateWiFiQRCode();
        }
    }

    public string WiFiPassword
    {
        get => _wifiPassword;
        set
        {
            _wifiPassword = value;
            OnPropertyChanged();
            SaveWiFiCredentials();
            GenerateWiFiQRCode();
        }
    }

    public string WiFiEncryption
    {
        get => _wifiEncryption;
        set
        {
            _wifiEncryption = value;
            OnPropertyChanged();
            SaveWiFiCredentials();
            GenerateWiFiQRCode();
        }
    }

    public ObservableCollection<string> WiFiEncryptionOptions { get; } = new()
    {
        "WPA",
        "WEP",
        "nopass"
    };

    // Endpoint Properties
    public string MoxieEndpoint
    {
        get => _moxieEndpoint;
        set
        {
            _moxieEndpoint = value;
            OnPropertyChanged();
            GenerateNetworkQRCode();
        }
    }

    // API Key Properties
    public string OpenAIKey
    {
        get => _openAIKey;
        set
        {
            _openAIKey = value;
            OnPropertyChanged();
            SaveOpenAIKey(value);
        }
    }

    public bool ShowingApiKey
    {
        get => _showingApiKey;
        set { _showingApiKey = value; OnPropertyChanged(); }
    }

    // PIN Properties
    public string CreatePIN
    {
        get => _createPIN;
        set
        {
            if (value.Length <= 6)
            {
                _createPIN = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(CanContinuePIN));
                OnPropertyChanged(nameof(IsPINLengthValid));
                OnPropertyChanged(nameof(DoPINsMatch));
            }
        }
    }

    public string ConfirmPIN
    {
        get => _confirmPIN;
        set
        {
            if (value.Length <= 6)
            {
                _confirmPIN = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(CanContinuePIN));
                OnPropertyChanged(nameof(DoPINsMatch));
            }
        }
    }

    public string ParentEmail
    {
        get => _parentEmail;
        set
        {
            _parentEmail = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(CanContinuePIN));
            OnPropertyChanged(nameof(IsEmailValid));
        }
    }

    // PIN Validation Properties
    public bool IsPINLengthValid => CreatePIN.Length == 6;
    public bool DoPINsMatch => !string.IsNullOrEmpty(CreatePIN) && CreatePIN == ConfirmPIN;
    public bool IsEmailValid => IsValidEmail(ParentEmail);

    public bool CanContinuePIN =>
        CreatePIN.Length == 6 &&
        CreatePIN == ConfirmPIN &&
        CreatePIN.All(char.IsDigit) &&
        IsValidEmail(ParentEmail);

    // QR Code Properties
    public BitmapSource? WiFiQRCode
    {
        get => _wifiQRCode;
        set { _wifiQRCode = value; OnPropertyChanged(); }
    }

    public BitmapSource? NetworkQRCode
    {
        get => _networkQRCode;
        set { _networkQRCode = value; OnPropertyChanged(); }
    }

    // Commands
    public ICommand NextCommand { get; }
    public ICommand PreviousCommand { get; }
    public ICommand SkipCommand { get; }
    public ICommand CancelCommand { get; }
    public ICommand CheckDockerCommand { get; }
    public ICommand DownloadDockerCommand { get; }
    public ICommand AutoInstallDependenciesCommand { get; }

    // Navigation Properties
    public bool CanGoPrevious => CurrentStep > 0;
    public string NextButtonText => CurrentStep == 6 ? "Get Started" : "Continue";

    // Step Execution
    private void ExecuteNext()
    {
        if (CurrentStep == 6)
        {
            // Mark setup as complete
            Properties.Settings.Default.HasCompletedSetup = true;
            Properties.Settings.Default.Save();
            // Close wizard - handled by view
            return;
        }

        // Save PIN when moving from PIN setup step (only if filled)
        if (CurrentStep == 2 && CanContinuePIN)
        {
            SavePINSettings();
        }

        CurrentStep++;
    }

    private bool CanExecuteNext()
    {
        // On PIN step, only allow continue if validation passes
        if (CurrentStep == 2)
        {
            return CanContinuePIN;
        }
        return true;
    }

    private void ExecutePrevious()
    {
        if (CurrentStep > 0)
        {
            CurrentStep--;
        }
    }

    private bool CanExecutePrevious()
    {
        return CurrentStep > 0;
    }

    private void ExecuteSkip()
    {
        if (CurrentStep < 6)
        {
            CurrentStep++;
        }
    }

    private void ExecuteCancel()
    {
        // Close wizard - handled by view
    }

    // Docker Check
    private async Task CheckDockerAsync()
    {
        IsChecking = true;
        CheckStatus = "";
        CanContinue = false;

        await Task.Delay(1000); // Small delay for better UX

        var installed = await _installService.CheckDockerInstalledAsync();

        DockerInstalled = installed;
        CheckStatus = installed
            ? "Docker is installed and ready!"
            : "Docker Desktop is not installed";
        CanContinue = installed;

        IsChecking = false;
    }

    private void DownloadDocker()
    {
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = "https://www.docker.com/products/docker-desktop/",
            UseShellExecute = true
        });
    }

    private async Task AutoInstallDependenciesAsync()
    {
        await _installService.RunCompleteSetupAsync();
    }

    // Settings Management
    private void LoadSettings()
    {
        WiFiSSID = Properties.Settings.Default.WiFiSSID ?? "";
        WiFiPassword = Properties.Settings.Default.WiFiPassword ?? "";
        WiFiEncryption = Properties.Settings.Default.WiFiEncryption ?? "WPA";
        MoxieEndpoint = Properties.Settings.Default.MoxieEndpoint ?? "http://localhost:8003/hive/endpoint/";
    }

    private void SaveWiFiCredentials()
    {
        Properties.Settings.Default.WiFiSSID = WiFiSSID;
        Properties.Settings.Default.WiFiPassword = WiFiPassword;
        Properties.Settings.Default.WiFiEncryption = WiFiEncryption;
        Properties.Settings.Default.Save();
    }

    private void SaveOpenAIKey(string key)
    {
        // Save to settings
        Properties.Settings.Default.OpenAIKey = key;
        Properties.Settings.Default.Save();

        // TODO: Update AIProviderManager when implemented
    }

    private void AutoDetectOpenAIKey()
    {
        // Check if key already exists in settings
        var existingKey = Properties.Settings.Default.OpenAIKey;
        if (!string.IsNullOrEmpty(existingKey))
        {
            OpenAIKey = existingKey;
            return;
        }

        // Check environment variable
        var envKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY");
        if (!string.IsNullOrEmpty(envKey))
        {
            OpenAIKey = envKey;
        }
    }

    private void SavePINSettings()
    {
        try
        {
            // Create PIN
            _pinService.CreatePIN(CreatePIN);

            // Save parent email
            Properties.Settings.Default.ParentEmail = ParentEmail;
            Properties.Settings.Default.Save();
        }
        catch (Exception ex)
        {
            CheckStatus = $"Failed to save PIN: {ex.Message}";
        }
    }

    // QR Code Generation
    private void GenerateWiFiQRCode()
    {
        if (string.IsNullOrEmpty(WiFiSSID))
        {
            WiFiQRCode = null;
            return;
        }

        // WiFi QR code format: WIFI:T:WPA;S:MyNetwork;P:MyPassword;;
        var wifiString = $"WIFI:T:{WiFiEncryption};S:{WiFiSSID};P:{WiFiPassword};;";
        WiFiQRCode = GenerateQRCode(wifiString);
    }

    private void GenerateNetworkQRCode()
    {
        NetworkQRCode = GenerateQRCode(MoxieEndpoint);
    }

    private BitmapSource? GenerateQRCode(string content)
    {
        try
        {
            var writer = new BarcodeWriter
            {
                Format = BarcodeFormat.QR_CODE,
                Options = new EncodingOptions
                {
                    Width = 300,
                    Height = 300,
                    Margin = 1
                }
            };

            return writer.Write(content);
        }
        catch
        {
            return null;
        }
    }

    // Validation
    private bool IsValidEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;

        var emailRegex = new Regex(@"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$");
        return emailRegex.IsMatch(email);
    }

    // INotifyPropertyChanged
    public event PropertyChangedEventHandler? PropertyChanged;

    protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}

// RelayCommand Helper
public class RelayCommand : ICommand
{
    private readonly Action _execute;
    private readonly Func<bool>? _canExecute;

    public RelayCommand(Action execute, Func<bool>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public event EventHandler? CanExecuteChanged
    {
        add => CommandManager.RequerySuggested += value;
        remove => CommandManager.RequerySuggested -= value;
    }

    public bool CanExecute(object? parameter) => _canExecute?.Invoke() ?? true;
    public void Execute(object? parameter) => _execute();
}
