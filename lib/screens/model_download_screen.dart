import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../providers/smart_pen_provider.dart';
import '../l10n/app_localizations.dart';

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({Key? key}) : super(key: key);

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  final Map<String, ModelDownloadStatus> _modelStatus = {
    'en': ModelDownloadStatus.notStarted,
    'fr': ModelDownloadStatus.notStarted,
    'ar': ModelDownloadStatus.notStarted,
  };

  final Map<String, String> _modelNames = {
    'en': 'english',
    'fr': 'french',
    'ar': 'arabic',
  };

  bool _isDownloading = false;
  String? _currentDownloadingModel;
  bool _isConnectedToInternet = false;
  bool _checkingConnection = true;
  String? _publicIpAddress;
  GooglePlayServicesAvailability? _playServicesStatus;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkGooglePlayServices();
    _checkInternetConnection();
    _checkExistingModels();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupConnectivityListener() {
    debugPrint('🎧 Setting up connectivity listener...');
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        debugPrint('📶 Connectivity changed: $results');
        _checkInternetConnection();
      },
    );
  }

  Future<void> _checkGooglePlayServices() async {
    if (!Platform.isAndroid) {
      debugPrint('ℹ️ Not on Android - Google Play Services check skipped');
      return;
    }

    try {
      debugPrint('🔍 Checking Google Play Services availability...');
      final availability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      
      setState(() {
        _playServicesStatus = availability;
      });
      
      debugPrint('📱 Google Play Services status: $availability');
      
      switch (availability) {
        case GooglePlayServicesAvailability.success:
          debugPrint('✅ Google Play Services is available and up to date');
          break;
        case GooglePlayServicesAvailability.serviceVersionUpdateRequired:
          debugPrint('⚠️ Google Play Services needs to be updated');
          break;
        case GooglePlayServicesAvailability.serviceMissing:
          debugPrint('❌ Google Play Services is missing');
          break;
        case GooglePlayServicesAvailability.serviceDisabled:
          debugPrint('❌ Google Play Services is disabled');
          break;
        case GooglePlayServicesAvailability.serviceInvalid:
          debugPrint('❌ Google Play Services installation is invalid');
          break;
        default:
          debugPrint('⚠️ Google Play Services status: $availability');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking Google Play Services: $e');
    }
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _checkingConnection = true;
    });

    try {
      debugPrint('🌐 Checking internet connection...');
      
      // Step 1: Check network connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      debugPrint('📶 Connectivity status: $connectivityResult');
      
      // Step 2: Verify actual internet access by pinging a reliable server
      bool hasInternet = false;
      
      if (connectivityResult.contains(ConnectivityResult.mobile) || 
          connectivityResult.contains(ConnectivityResult.wifi)) {
        debugPrint('📡 Network adapter connected, testing actual internet access...');
        
        try {
          // Try to reach Google's DNS (reliable and fast)
          final result = await InternetAddress.lookup('google.com')
              .timeout(Duration(seconds: 5));
          
          hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
          debugPrint(hasInternet 
              ? '✅ Successfully reached google.com - Internet is available'
              : '❌ Could not resolve google.com - No internet');
              
          // Step 3: Get public IP address for absolute confirmation
          if (hasInternet) {
            try {
              debugPrint('🌍 Fetching public IP address from ifconfig.me...');
              final httpClient = HttpClient();
              final request = await httpClient.getUrl(Uri.parse('https://ifconfig.me'))
                  .timeout(Duration(seconds: 5));
              
              // Set User-Agent to mimic curl so ifconfig.me returns plain text IP
              request.headers.set('User-Agent', 'curl/8.5.0');
              
              final response = await request.close().timeout(Duration(seconds: 5));
              
              if (response.statusCode == 200) {
                final publicIp = await response.transform(utf8.decoder).join();
                debugPrint('🌐 Public IP Address: $publicIp');
                debugPrint('✅ Internet connectivity absolutely confirmed');
                
                setState(() {
                  _publicIpAddress = publicIp.trim();
                });
              } else {
                debugPrint('⚠️ ifconfig.me returned status: ${response.statusCode}');
                setState(() {
                  _publicIpAddress = null;
                });
              }
              
              httpClient.close();
            } catch (e) {
              debugPrint('⚠️ Could not fetch public IP (but internet seems available): $e');
              setState(() {
                _publicIpAddress = null;
              });
            }
          } else {
            setState(() {
              _publicIpAddress = null;
            });
          }
        } on SocketException catch (e) {
          debugPrint('❌ Socket exception: $e - No internet access');
          hasInternet = false;
        } on TimeoutException catch (e) {
          debugPrint('⏱️ Timeout: $e - No internet access');
          hasInternet = false;
        }
      } else {
        debugPrint('📵 No network adapter connected (no WiFi/mobile data)');
      }
      
      setState(() {
        _isConnectedToInternet = hasInternet;
        _checkingConnection = false;
      });
      
      debugPrint(_isConnectedToInternet 
          ? '✅ Internet connection confirmed' 
          : '❌ No internet connection detected');
    } catch (e) {
      debugPrint('⚠️ Failed to check internet connection: $e');
      setState(() {
        _isConnectedToInternet = false;
        _checkingConnection = false;
      });
    }
  }

  Future<void> _checkExistingModels() async {
    debugPrint('🔍 ModelDownloadScreen: Checking existing models...');
    final provider = context.read<SmartPenProvider>();
    for (final lang in _modelStatus.keys) {
      debugPrint('🔍 Checking status for: $lang');
      final status = await provider.translationService.checkModelStatus(lang);
      debugPrint('📊 Status for $lang: $status');
      if (mounted) {
        setState(() {
          _modelStatus[lang] = status;
        });
      }
    }
    debugPrint('✅ Finished checking all models');
  }

  Future<void> _downloadAllModels() async {
    debugPrint('🚀 _downloadAllModels called');
    if (_isDownloading) {
      debugPrint('⚠️ Already downloading - skipping');
      return;
    }

    debugPrint('📋 Setting downloading state to true');
    setState(() {
      _isDownloading = true;
    });

    debugPrint('📋 Getting models to download...');
    final provider = context.read<SmartPenProvider>();
    final modelsToDownload = _modelStatus.entries
        .where((e) => e.value != ModelDownloadStatus.downloaded)
        .map((e) => e.key)
        .toList();

    debugPrint('📋 Models to download: $modelsToDownload');

    for (final lang in modelsToDownload) {
      if (!mounted) {
        debugPrint('⚠️ Widget unmounted - stopping downloads');
        break;
      }

      debugPrint('📥 Starting download for: $lang');
      setState(() {
        _currentDownloadingModel = lang;
        _modelStatus[lang] = ModelDownloadStatus.downloading;
      });

      try {
        debugPrint('🌐 Calling provider.translationService.downloadModel($lang)...');
        await provider.translationService.downloadModel(
          lang,
          onProgress: (progress) {
            debugPrint('📊 Download progress for $lang: ${(progress * 100).toStringAsFixed(0)}%');
            // Progress updates handled by the service
          },
        );

        debugPrint('✅ Download successful for: $lang');
        if (mounted) {
          setState(() {
            _modelStatus[lang] = ModelDownloadStatus.downloaded;
          });
        }
      } catch (e) {
        debugPrint('❌ Download failed for $lang: $e');
        if (mounted) {
          setState(() {
            _modelStatus[lang] = ModelDownloadStatus.error;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr('downloadFailed').replaceAll('{model}', context.tr(_modelNames[lang]!))}: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }

    debugPrint('🏁 Finished downloading all models');
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _currentDownloadingModel = null;
      });

      if (_modelStatus.values.every((s) => s == ModelDownloadStatus.downloaded)) {
        debugPrint('🎉 All models downloaded successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('allModelsDownloaded')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _downloadSingleModel(String lang) async {
    debugPrint('🚀 _downloadSingleModel called for: $lang');
    if (_isDownloading) {
      debugPrint('⚠️ Already downloading another model - skipping');
      return;
    }

    debugPrint('📋 Setting downloading state...');
    setState(() {
      _isDownloading = true;
      _currentDownloadingModel = lang;
      _modelStatus[lang] = ModelDownloadStatus.downloading;
    });

    debugPrint('📋 Getting translation service...');
    final provider = context.read<SmartPenProvider>();

    try {
      debugPrint('🌐 Starting download for $lang...');
      await provider.translationService.downloadModel(lang);

      debugPrint('✅ Download completed for $lang');
      if (mounted) {
        setState(() {
          _modelStatus[lang] = ModelDownloadStatus.downloaded;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('modelDownloaded')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Download failed for $lang: $e');
      if (mounted) {
        setState(() {
          _modelStatus[lang] = ModelDownloadStatus.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('downloadFailed').replaceAll('{model}', context.tr(_modelNames[lang]!))}: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      debugPrint('🏁 Cleaning up download state for $lang');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _currentDownloadingModel = null;
        });
      }
    }
  }

  Future<void> _deleteModel(String lang) async {
    final provider = context.read<SmartPenProvider>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deleteModel')),
        content: Text(context.tr('deleteModelConfirm').replaceAll('{model}', context.tr(_modelNames[lang]!))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.translationService.deleteModel(lang);
        if (mounted) {
          setState(() {
            _modelStatus[lang] = ModelDownloadStatus.notStarted;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('modelDeleted'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr('deleteFailed')}: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDownloaded = _modelStatus.values.every((s) => s == ModelDownloadStatus.downloaded);
    final hasErrors = _modelStatus.values.any((s) => s == ModelDownloadStatus.error);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('translationModels')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      allDownloaded ? Icons.check_circle : Icons.download,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        allDownloaded
                            ? context.tr('allModelsDownloaded')
                            : context.tr('downloadTranslationModels'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('downloadModelsDescription'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                // Internet Connection Indicator
                _buildConnectionIndicator(),
              ],
            ),
          ),

          // Model List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._modelStatus.entries.map((entry) {
                  return _buildModelCard(entry.key, entry.value);
                }),
                const SizedBox(height: 16),
                
                // Google Play Services Warning (Android only)
                if (Platform.isAndroid && _playServicesStatus != null && 
                    _playServicesStatus != GooglePlayServicesAvailability.success)
                  _buildPlayServicesWarning(),
                
                if (Platform.isAndroid && _playServicesStatus != null && 
                    _playServicesStatus != GooglePlayServicesAvailability.success)
                  const SizedBox(height: 16),
                
                // Download All Button
                if (!allDownloaded)
                  ElevatedButton.icon(
                    onPressed: (_isDownloading || !_isConnectedToInternet) ? null : _downloadAllModels,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isDownloading 
                        ? context.tr('downloading')
                        : !_isConnectedToInternet 
                            ? context.tr('noInternetConnection')
                            : context.tr('downloadAllModels')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (allDownloaded)
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('readyToTranslate'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('modelsInstalled'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (hasErrors)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('downloadError'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('downloadErrorDesc'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_isConnectedToInternet && !_checkingConnection && !allDownloaded)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('internetRequired'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('internetRequiredDesc'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    if (_checkingConnection) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('checkingConnection'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnectedToInternet 
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isConnectedToInternet 
              ? Colors.green.shade200
              : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isConnectedToInternet 
                      ? context.tr('connectedToInternet')
                      : context.tr('noInternetConnection'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isConnectedToInternet && _publicIpAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'IP: $_publicIpAddress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _checkInternetConnection,
            child: Icon(
              Icons.refresh,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(String lang, ModelDownloadStatus status) {
    final isCurrentlyDownloading = _currentDownloadingModel == lang;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(status, isCurrentlyDownloading),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(_modelNames[lang]!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(status, isCurrentlyDownloading),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(lang, status),
              ],
            ),
            if (isCurrentlyDownloading && status == ModelDownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                context.tr('downloadInProgress'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ModelDownloadStatus status, bool isDownloading) {
    if (isDownloading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    switch (status) {
      case ModelDownloadStatus.downloaded:
        return Icon(Icons.check_circle, color: Colors.green.shade700, size: 40);
      case ModelDownloadStatus.downloading:
        return const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case ModelDownloadStatus.error:
        return Icon(Icons.error, color: Colors.red.shade700, size: 40);
      case ModelDownloadStatus.notStarted:
        return Icon(Icons.cloud_download, color: Colors.grey.shade600, size: 40);
    }
  }

  Widget _buildActionButton(String lang, ModelDownloadStatus status) {
    if (status == ModelDownloadStatus.downloaded) {
      return IconButton(
        onPressed: _isDownloading ? null : () => _deleteModel(lang),
        icon: const Icon(Icons.delete),
        tooltip: context.tr('deleteModel'),
        color: Colors.red.shade700,
      );
    }

    if (status == ModelDownloadStatus.error) {
      return TextButton.icon(
        onPressed: _isDownloading ? null : () => _downloadSingleModel(lang),
        icon: const Icon(Icons.refresh, size: 20),
        label: Text(context.tr('retry')),
      );
    }

    if (status == ModelDownloadStatus.notStarted) {
      return ElevatedButton.icon(
        onPressed: (_isDownloading || !_isConnectedToInternet) ? null : () => _downloadSingleModel(lang),
        icon: const Icon(Icons.download, size: 20),
        label: Text(!_isConnectedToInternet ? context.tr('noInternet') : context.tr('download')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getStatusText(ModelDownloadStatus status, bool isDownloading) {
    if (isDownloading) return context.tr('downloadingModel');
    
    switch (status) {
      case ModelDownloadStatus.downloaded:
        return context.tr('downloadedReady');
      case ModelDownloadStatus.downloading:
        return context.tr('downloading');
      case ModelDownloadStatus.error:
        return context.tr('downloadFailedStatus');
      case ModelDownloadStatus.notStarted:
        return context.tr('notDownloaded');
    }
  }

  Color _getStatusColor(ModelDownloadStatus status) {
    switch (status) {
      case ModelDownloadStatus.downloaded:
        return Colors.green.shade700;
      case ModelDownloadStatus.downloading:
        return Theme.of(context).colorScheme.primary;
      case ModelDownloadStatus.error:
        return Colors.red.shade700;
      case ModelDownloadStatus.notStarted:
        return Colors.grey.shade600;
    }
  }

  Widget _buildPlayServicesWarning() {
    String title;
    String message;
    IconData icon;
    MaterialColor colorMaterial;

    switch (_playServicesStatus) {
      case GooglePlayServicesAvailability.serviceVersionUpdateRequired:
        title = 'Google Play Services Update Required';
        message = 'ML Kit translation requires an updated version of Google Play Services. Please update it from the Google Play Store.';
        icon = Icons.system_update;
        colorMaterial = Colors.orange;
        break;
      case GooglePlayServicesAvailability.serviceMissing:
        title = 'Google Play Services Missing';
        message = 'ML Kit translation requires Google Play Services, which is not installed on this device. Please install it from the Google Play Store.';
        icon = Icons.error_outline;
        colorMaterial = Colors.red;
        break;
      case GooglePlayServicesAvailability.serviceDisabled:
        title = 'Google Play Services Disabled';
        message = 'Google Play Services is disabled on this device. Please enable it in your device settings to download translation models.';
        icon = Icons.block;
        colorMaterial = Colors.red;
        break;
      case GooglePlayServicesAvailability.serviceInvalid:
        title = 'Google Play Services Invalid';
        message = 'The Google Play Services installation on this device is invalid. Please reinstall it from the Google Play Store.';
        icon = Icons.warning;
        colorMaterial = Colors.red;
        break;
      default:
        title = 'Google Play Services Issue';
        message = 'There may be an issue with Google Play Services on this device. ML Kit translation might not work properly.';
        icon = Icons.warning;
        colorMaterial = Colors.orange;
    }

    return Card(
      color: colorMaterial.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorMaterial.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorMaterial.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorMaterial.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ModelDownloadStatus {
  notStarted,
  downloading,
  downloaded,
  error,
}
