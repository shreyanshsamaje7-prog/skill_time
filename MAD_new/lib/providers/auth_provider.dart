import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firestore_repository.dart';
import '../models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(firestoreRepositoryProvider).getUserProfile(user.uid);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authRepository.signUpWithEmailPassword(email, password);
      // Create profile in firestore
      final userProfile = UserProfile(
        id: credential.user!.uid,
        name: name,
        email: email,
        username: email.split('@')[0],
        bio: '',
        skills: [],
        joinedDate: DateTime.now(),
        streaks: 0,
        xpPoints: 0,
        level: 1,
      );
      await FirestoreRepository().createUserProfile(userProfile);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authRepository.signInWithGoogle();
      if (credential != null && credential.additionalUserInfo?.isNewUser == true) {
        // Create profile in firestore for new google user
        final userProfile = UserProfile(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? 'User',
          email: credential.user!.email ?? '',
          username: (credential.user!.email ?? 'user').split('@')[0],
          profileImage: credential.user!.photoURL,
          bio: '',
          skills: [],
          joinedDate: DateTime.now(),
          streaks: 0,
          xpPoints: 0,
          level: 1,
        );
        await FirestoreRepository().createUserProfile(userProfile);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
