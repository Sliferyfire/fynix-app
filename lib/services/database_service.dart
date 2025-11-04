import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTasks() async {
    final response = await supabase.from('tasks').select();
    return response;
  }
  
}
