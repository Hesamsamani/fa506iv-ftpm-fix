using System.Diagnostics;
using System.Security.Principal;
using System.Windows;

namespace FA506IV.FTPMFix.Gui.Services;

public static class AdminHelper
{
    public static bool IsAdministrator()
    {
        using var identity = WindowsIdentity.GetCurrent();
        var principal = new WindowsPrincipal(identity);
        return principal.IsInRole(WindowsBuiltInRole.Administrator);
    }

    public static bool TryRelaunchAsAdministrator()
    {
        var exe = Environment.ProcessPath ?? Process.GetCurrentProcess().MainModule?.FileName;
        if (string.IsNullOrWhiteSpace(exe))
        {
            MessageBox.Show(
                "Could not determine the application path for elevation.",
                "Administrator required",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
            return false;
        }

        var proceed = MessageBox.Show(
            "FA506IV fTPM Fix must run as Administrator to manage BIOS staging, USB prep, and TPM tools.\n\n" +
            "Click OK to approve the Windows UAC prompt.",
            "Administrator required",
            MessageBoxButton.OKCancel,
            MessageBoxImage.Information);
        if (proceed != MessageBoxResult.OK)
        {
            return false;
        }

        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = exe,
                UseShellExecute = true,
                Verb = "runas",
            });
            Application.Current.Shutdown();
            return true;
        }
        catch (System.ComponentModel.Win32Exception)
        {
            MessageBox.Show(
                "Elevation was cancelled or denied. Re-launch the app and choose Run as administrator.",
                "Administrator required",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return false;
        }
    }
}