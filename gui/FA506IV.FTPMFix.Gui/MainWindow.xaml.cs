using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using FA506IV.FTPMFix.Gui.Services;

namespace FA506IV.FTPMFix.Gui;

public partial class MainWindow : Window
{
    private readonly PowerShellRunner _runner = new();
    private readonly PayloadManager _payload = PayloadManager.Instance;
    private bool _busy;

    public MainWindow()
    {
        InitializeComponent();
        Loaded += MainWindow_Loaded;
    }

    private async void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        if (!AdminHelper.IsAdministrator())
        {
            AdminBadge.Text = "Not admin — relaunching…";
            AdminBadge.Foreground = (Brush)FindResource("WarnBrush");
            AdminHelper.RelaunchAsAdministrator();
            return;
        }

        AdminBadge.Text = "Administrator";
        AdminBadge.Foreground = (Brush)FindResource("OkBrush");
        Log("Payload: " + _payload.Root);
        await RefreshStatusAsync();
    }

    private async void RefreshButton_Click(object sender, RoutedEventArgs e) => await RefreshStatusAsync();

    private async void CleanupButton_Click(object sender, RoutedEventArgs e)
    {
        if (!Confirm("Clean up failed Windows /fw flash state?\n\nThis resets registry Phase 2 / 0xC0000001 and restores stock ROM staging."))
        {
            return;
        }

        await RunInstallerScriptAsync(
            Path.Combine(_payload.ScriptsDir, "Cleanup_FailedFirmwareFlash.ps1"),
            "-NonInteractive");
    }

    private async void EzFlashButton_Click(object sender, RoutedEventArgs e)
    {
        var drive = PromptDriveLetter();
        if (string.IsNullOrWhiteSpace(drive))
        {
            return;
        }

        await RunInstallerScriptAsync(
            Path.Combine(_payload.ScriptsDir, "Prepare_EZFlash_USB.ps1"),
            "-DriveLetter", drive);
    }

    private async void InstallButton_Click(object sender, RoutedEventArgs e)
    {
        if (!Confirm("Stage patched ROM locally?\n\nThis does NOT flash hardware. Windows /fw cannot apply patched ROMs on FA506IV.\nUse Prepare EZ Flash USB instead."))
        {
            return;
        }

        await RunInstallerScriptAsync(
            Path.Combine(_payload.InstallerDir, "BIOSInstall_FTPMFix.ps1"),
            "-NonInteractive", "-SkipReboot");
    }

    private async void RepairButton_Click(object sender, RoutedEventArgs e)
    {
        if (!Confirm("Repair firmware flash staging? Fixes DriverStore + registry pending state."))
        {
            return;
        }

        await RunInstallerScriptAsync(
            Path.Combine(_payload.ScriptsDir, "Repair_FirmwareFlash.ps1"),
            "-ReinstallDriver", "-NonInteractive");
    }

    private void FwRebootButton_Click(object sender, RoutedEventArgs e)
    {
        MessageBox.Show(
            "Windows /fw firmware flash cannot apply the patched ROM on FA506IV.\n\n" +
            "The signed catalog (oem96.cat) only covers the stock ASUS image. " +
            "A /fw reboot will fail with LastAttemptStatus 0xC0000001 and may leave Phase 2.\n\n" +
            "Use Prepare EZ Flash USB, then flash from BIOS (F2 → ASUS EZ Flash 3).",
            "/fw blocked",
            MessageBoxButton.OK,
            MessageBoxImage.Warning);
    }

    private async void VerifyButton_Click(object sender, RoutedEventArgs e)
    {
        await RunInstallerScriptAsync(
            Path.Combine(_payload.ScriptsDir, "verify_flash_status.ps1"));
    }

    private async void ClearTpmButton_Click(object sender, RoutedEventArgs e)
    {
        if (!Confirm("Clear TPM and reboot? Only do this AFTER TPM version is no longer 3.42.0.5."))
        {
            return;
        }

        await RunInstallerScriptAsync(
            Path.Combine(_payload.ScriptsDir, "post_flash_tpm.ps1"),
            "-NonInteractive");
    }

    private async void AttestationCheckButton_Click(object sender, RoutedEventArgs e)
    {
        await RunAttestationCheckAsync();
    }

    private void LaunchWizardButton_Click(object sender, RoutedEventArgs e)
    {
        var wizard = _payload.WizardExe;
        if (!File.Exists(wizard))
        {
            Log("COD wizard not bundled. Download from Activision support page.");
            Process.Start(new ProcessStartInfo
            {
                FileName = "https://support.activision.com/articles/secure-attestation-wizard",
                UseShellExecute = true,
            });
            MessageBox.Show(
                "COD Secure Attestation Wizard was not found in the package.\n\n" +
                "Opening Activision download page in your browser.\n" +
                "After extracting CODSecureAttestationWizard.exe, you can run it manually.",
                "Wizard not bundled",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            return;
        }

        Log("Launching Call of Duty Secure Attestation Wizard v1.0.5…");
        Process.Start(new ProcessStartInfo
        {
            FileName = wizard,
            WorkingDirectory = Path.GetDirectoryName(wizard)!,
            UseShellExecute = true,
        });
    }

    private async void RollbackButton_Click(object sender, RoutedEventArgs e)
    {
        if (!Confirm("Rollback to STOCK ASUS BIOS? This schedules a firmware reboot."))
        {
            return;
        }

        await RunInstallerScriptAsync(
            Path.Combine(_payload.InstallerDir, "Rollback_Stock.ps1"),
            "-NonInteractive");
    }

    private async Task RefreshStatusAsync()
    {
        var statusScript = Path.Combine(_payload.ScriptsDir, "gui_status.ps1");
        var result = await _runner.RunScriptAsync(statusScript);
        if (!result.Success)
        {
            Log("Status refresh failed:\n" + result.StdErr + result.StdOut);
            return;
        }

        try
        {
            using var doc = JsonDocument.Parse(result.StdOut.Trim());
            ApplyStatus(doc.RootElement);
        }
        catch (Exception ex)
        {
            Log("Failed to parse status JSON: " + ex.Message);
        }

        await RunAttestationCheckAsync(silent: true);
    }

    private void ApplyStatus(JsonElement root)
    {
        ModelValue.Text = root.GetProperty("Model").GetString() ?? "—";
        BiosValue.Text = "BIOS " + (root.GetProperty("BiosVersion").GetString() ?? "—");

        if (root.TryGetProperty("Tpm", out var tpm) && tpm.TryGetProperty("ManufacturerVersion", out var ver))
        {
            var version = ver.GetString() ?? "—";
            TpmVersionValue.Text = version;
            TpmVersionValue.Foreground = version == "3.42.0.5"
                ? (Brush)FindResource("ErrBrush")
                : (Brush)FindResource("OkBrush");
            var pending = tpm.TryGetProperty("RestartPending", out var rp) && rp.GetBoolean();
            TpmSubValue.Text = pending ? "Restart pending" : (tpm.TryGetProperty("ManufacturerId", out var mid) ? mid.GetString() : "");
        }

        if (root.TryGetProperty("Flash", out var flash))
        {
            var tpmBad = root.TryGetProperty("Tpm", out var tpmEl)
                && tpmEl.TryGetProperty("ManufacturerVersion", out var mv)
                && mv.GetString() == "3.42.0.5";
            var windowsFailed = flash.TryGetProperty("WindowsFlashFailed", out var wf) && wf.GetBoolean();
            var needsCleanup = flash.TryGetProperty("NeedsCleanup", out var nc) && nc.GetBoolean();

            if (!tpmBad)
            {
                FlashValue.Text = "BIOS patched";
                FlashValue.Foreground = (Brush)FindResource("OkBrush");
                FlashSubValue.Text = tpmEl.TryGetProperty("ManufacturerVersion", out var tv)
                    ? "TPM " + tv.GetString()
                    : "";
            }
            else if (windowsFailed || needsCleanup)
            {
                FlashValue.Text = "/fw flash failed";
                FlashValue.Foreground = (Brush)FindResource("ErrBrush");
                FlashSubValue.Text = "Click Cleanup, then Prepare EZ Flash USB";
            }
            else
            {
                FlashValue.Text = "Use EZ Flash USB";
                FlashValue.Foreground = (Brush)FindResource("WarnBrush");
                FlashSubValue.Text = "Windows /fw cannot apply patched ROM";
            }
        }
    }

    private async Task RunAttestationCheckAsync(bool silent = false)
    {
        var script = Path.Combine(_payload.ScriptsDir, "gui_attestation_check.ps1");
        var result = await _runner.RunScriptAsync(script);
        if (!result.Success)
        {
            if (!silent)
            {
                Log("Attestation pre-check failed:\n" + result.StdErr + result.StdOut);
            }
            return;
        }

        try
        {
            using var doc = JsonDocument.Parse(result.StdOut.Trim());
            var root = doc.RootElement;
            var pass = root.GetProperty("CodWizardLikelyPass").GetBoolean();
            var summary = root.GetProperty("Summary").GetString() ?? "";

            AttestationValue.Text = pass ? "Likely PASS" : "Likely FAIL";
            AttestationValue.Foreground = pass
                ? (Brush)FindResource("OkBrush")
                : (Brush)FindResource("ErrBrush");

            AttestationDetailText.Text = summary;
            AttestationDetailText.Foreground = pass
                ? (Brush)FindResource("OkBrush")
                : (Brush)FindResource("WarnBrush");

            if (!silent)
            {
                Log("COD attestation pre-check (wizard v1.0.5):\n" + summary);
                if (root.TryGetProperty("Failures", out var failures))
                {
                    foreach (var item in failures.EnumerateArray())
                    {
                        Log("  • " + item.GetString());
                    }
                }
            }
        }
        catch (Exception ex)
        {
            if (!silent)
            {
                Log("Failed to parse attestation JSON: " + ex.Message);
            }
        }
    }

    private async Task RunInstallerScriptAsync(string scriptPath, params string[] extraArgs)
    {
        if (_busy)
        {
            return;
        }

        if (!File.Exists(scriptPath))
        {
            Log("Missing script: " + scriptPath);
            MessageBox.Show("Script not found:\n" + scriptPath, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            return;
        }

        SetBusy(true);
        Log($"Running {Path.GetFileName(scriptPath)} …");
        try
        {
            var result = await _runner.RunScriptAsync(scriptPath, extraArgs);
            if (!string.IsNullOrWhiteSpace(result.StdOut))
            {
                Log(result.StdOut.TrimEnd());
            }
            if (!string.IsNullOrWhiteSpace(result.StdErr))
            {
                Log(result.StdErr.TrimEnd());
            }

            Log(result.Success
                ? $"✓ {Path.GetFileName(scriptPath)} completed."
                : $"✗ {Path.GetFileName(scriptPath)} failed (exit {result.ExitCode}).");

            await RefreshStatusAsync();
        }
        finally
        {
            SetBusy(false);
        }
    }

    private void SetBusy(bool busy)
    {
        _busy = busy;
        CleanupButton.IsEnabled = !busy;
        EzFlashButton.IsEnabled = !busy;
        InstallButton.IsEnabled = !busy;
        RepairButton.IsEnabled = !busy;
        VerifyButton.IsEnabled = !busy;
        ClearTpmButton.IsEnabled = !busy;
        FwRebootButton.IsEnabled = !busy;
        AttestationCheckButton.IsEnabled = !busy;
        LaunchWizardButton.IsEnabled = !busy;
        RollbackButton.IsEnabled = !busy;
        RefreshButton.IsEnabled = !busy;
    }

    private static bool Confirm(string message) =>
        MessageBox.Show(message, "Confirm", MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes;

    private static string? PromptDriveLetter()
    {
        var input = new System.Windows.Controls.TextBox
        {
            Text = "E",
            MaxLength = 1,
            Width = 40,
            Margin = new Thickness(0, 8, 0, 0),
        };
        var panel = new System.Windows.Controls.StackPanel { Margin = new Thickness(16) };
        panel.Children.Add(new System.Windows.Controls.TextBlock
        {
            Text = "Enter the USB drive letter (FAT32 recommended):",
            TextWrapping = TextWrapping.Wrap,
            Width = 320,
        });
        panel.Children.Add(input);

        var dialog = new Window
        {
            Title = "Prepare EZ Flash USB",
            Content = panel,
            SizeToContent = SizeToContent.WidthAndHeight,
            WindowStartupLocation = WindowStartupLocation.CenterOwner,
            Owner = Application.Current.MainWindow,
            ResizeMode = ResizeMode.NoResize,
        };

        var buttons = new System.Windows.Controls.StackPanel
        {
            Orientation = System.Windows.Controls.Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
            Margin = new Thickness(16, 0, 16, 16),
        };
        var ok = new System.Windows.Controls.Button { Content = "OK", Width = 80, Margin = new Thickness(0, 0, 8, 0), IsDefault = true };
        var cancel = new System.Windows.Controls.Button { Content = "Cancel", Width = 80, IsCancel = true };
        string? result = null;
        ok.Click += (_, _) => { result = input.Text.Trim().TrimEnd(':'); dialog.DialogResult = true; };
        cancel.Click += (_, _) => { dialog.DialogResult = false; };
        buttons.Children.Add(ok);
        buttons.Children.Add(cancel);

        var root = new System.Windows.Controls.DockPanel();
        System.Windows.Controls.DockPanel.SetDock(buttons, System.Windows.Controls.Dock.Bottom);
        root.Children.Add(buttons);
        root.Children.Add(panel);
        dialog.Content = root;

        return dialog.ShowDialog() == true && !string.IsNullOrWhiteSpace(result)
            ? result.ToUpperInvariant()
            : null;
    }

    private void Log(string message)
    {
        LogBox.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
        LogBox.ScrollToEnd();
    }
}