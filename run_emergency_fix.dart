import 'dart:developer' as developer;
import 'database_backup.dart';

void main() async {
  developer.log('🚨 EMERGENCY DATABASE FIX STARTING...');

  // Step 1: Backup current database
  developer.log('\n📦 Step 1: Creating backup...');
  await DatabaseBackup.backupDatabase();

  // Step 2: Check current schema
  developer.log('\n🔍 Step 2: Checking current schema...');
  await DatabaseBackup.checkSchema();

  // Step 3: Run emergency migration
  developer.log('\n🔧 Step 3: Running emergency migration...');
  await DatabaseBackup.runEmergencyMigration();

  // Step 4: Verify fix
  developer.log('\n✅ Step 4: Verifying fix...');
  await DatabaseBackup.checkSchema();

  developer.log('\n🎉 EMERGENCY FIX COMPLETED!');
  developer.log('Please restart of application and test customer editing.');
}
