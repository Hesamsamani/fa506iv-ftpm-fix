using System.IO;
using System.IO.Compression;
using System.Reflection;

namespace FA506IV.FTPMFix.Gui.Services;

public sealed class PayloadManager
{
    public const string PayloadVersion = "1.3.1";

    private static PayloadManager? _instance;
    private string? _root;

    public static PayloadManager Instance => _instance ??= new PayloadManager();

    public string Root
    {
        get
        {
            if (_root is not null)
            {
                return _root;
            }

            var baseDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "FA506IV_fTPM_Fix",
                "payload"
            );

            var stamp = Path.Combine(baseDir, ".payload-version");
            var needsExtract = !Directory.Exists(baseDir) || !File.Exists(stamp);
            if (!needsExtract)
            {
                var existing = File.ReadAllText(stamp).Trim();
                needsExtract = !string.Equals(existing, PayloadVersion, StringComparison.Ordinal);
            }

            if (needsExtract)
            {
                if (Directory.Exists(baseDir))
                {
                    Directory.Delete(baseDir, recursive: true);
                }
                Directory.CreateDirectory(baseDir);
                ExtractEmbeddedPayload(baseDir);
                File.WriteAllText(stamp, PayloadVersion);
            }

            _root = baseDir;
            return _root;
        }
    }

    public string ScriptsDir => Path.Combine(Root, "scripts");
    public string InstallerDir => Path.Combine(Root, "windows-installer");
    public string WizardExe => Path.Combine(Root, "tools", "CODSecureAttestationWizard.exe");

    private static void ExtractEmbeddedPayload(string destination)
    {
        var assembly = Assembly.GetExecutingAssembly();
        var resourceName = assembly.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith("payload.zip", StringComparison.OrdinalIgnoreCase))
            ?? throw new InvalidOperationException("Embedded payload.zip not found.");

        using var stream = assembly.GetManifestResourceStream(resourceName)
            ?? throw new InvalidOperationException($"Cannot open resource: {resourceName}");

        var zipPath = Path.Combine(Path.GetTempPath(), $"fa506iv-payload-{Guid.NewGuid():N}.zip");
        try
        {
            using (var file = File.Create(zipPath))
            {
                stream.CopyTo(file);
            }

            ZipFile.ExtractToDirectory(zipPath, destination, overwriteFiles: true);
        }
        finally
        {
            if (File.Exists(zipPath))
            {
                File.Delete(zipPath);
            }
        }
    }
}