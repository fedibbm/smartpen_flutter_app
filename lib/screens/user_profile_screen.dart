import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isEditing = false;
  String _selectedReadingLevel = 'Beginner';
  String _selectedFontSize = 'Medium';
  List<String> _selectedDifficulties = [];
  
  final List<String> _readingLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _fontSizes = ['Small', 'Medium', 'Large', 'Extra Large'];
  final List<String> _commonDifficulties = [
    'Letter reversals (b/d, p/q)',
    'Word recognition',
    'Reading speed',
    'Comprehension',
    'Spelling',
    'Writing organization',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // Mock loading user data - in a real app, this would come from a database
    _nameController.text = 'sami ben salah';
    _ageController.text = '16';
    _emailController.text = 'bensalah.sami@email.com';
    _schoolController.text = 'Lycée 18 janvier';
    _notesController.text = 'Works best with simplified text and audio support.';
    _selectedReadingLevel = 'Intermediate';
    _selectedFontSize = 'Large';
    _selectedDifficulties = ['Letter reversals (b/d, p/q)', 'Reading speed'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _saveProfile();
                }
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Photo selection feature coming soon!'),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty ? 'User Name' : _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Personal Information
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _schoolController,
                    label: 'School/Institution',
                    icon: Icons.school,
                    enabled: _isEditing,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Reading Preferences
              _buildSectionCard(
                title: 'Reading Preferences',
                icon: Icons.auto_stories,
                children: [
                  _buildDropdownField(
                    label: 'Reading Level',
                    value: _selectedReadingLevel,
                    items: _readingLevels,
                    onChanged: _isEditing ? (value) {
                      setState(() {
                        _selectedReadingLevel = value!;
                      });
                    } : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Preferred Font Size',
                    value: _selectedFontSize,
                    items: _fontSizes,
                    onChanged: _isEditing ? (value) {
                      setState(() {
                        _selectedFontSize = value!;
                      });
                    } : null,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Learning Difficulties
              _buildSectionCard(
                title: 'Learning Challenges',
                icon: Icons.psychology,
                children: [
                  const Text(
                    'Select the areas you find challenging:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ..._commonDifficulties.map((difficulty) {
                    return CheckboxListTile(
                      title: Text(difficulty),
                      value: _selectedDifficulties.contains(difficulty),
                      onChanged: _isEditing ? (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedDifficulties.add(difficulty);
                          } else {
                            _selectedDifficulties.remove(difficulty);
                          }
                        });
                      } : null,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Additional Notes
              _buildSectionCard(
                title: 'Additional Notes',
                icon: Icons.note_outlined,
                children: [
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes about learning preferences, strategies that work, etc.',
                    icon: Icons.note,
                    maxLines: 4,
                    enabled: _isEditing,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _loadUserProfile(); // Reset to original values
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: onChanged == null,
        fillColor: onChanged == null ? Colors.grey.shade100 : null,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      // Mock saving - in a real app, this would save to a database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isEditing = false;
      });
    }
  }
}
