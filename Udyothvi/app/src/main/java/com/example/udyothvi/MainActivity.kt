package com.example.udyothvi

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.udyothvi.ui.theme.UdyothviTheme

class MainActivity : ComponentActivity() {
    private lateinit var sharedPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sharedPreferences = getSharedPreferences("UdyothviPrefs", MODE_PRIVATE)

        setContent {
            UdyothviTheme(darkTheme = false) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    UdyothviApp()
                }
            }
        }
    }
}

@Composable
fun UdyothviApp() {
    val navController = rememberNavController()
    val profileViewModel: ProfileViewModel = viewModel()

    NavHost(navController = navController, startDestination = "login") {
        composable("login") {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate("educational_qualification") {
                        popUpTo("login") { inclusive = true }
                    }
                },
                onGoogleSignInSuccess = {
                    navController.navigate("educational_qualification") {
                        popUpTo("login") { inclusive = true }
                    }
                },
                onRegisterClick = {
                    navController.navigate("registration")
                }
            )
        }
        composable("registration") {
            RegistrationForm(
                navController = navController,
                onRegistrationSuccess = {
                    navController.navigate("educational_qualification") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }
        composable("educational_qualification") {
            EducationalQualificationPage(
                navController = navController,
                onComplete = {
                    navController.navigate("add_skills") {
                        popUpTo("educational_qualification") { inclusive = true }
                            }
                        }
            )
        }
        composable("add_skills") {
            AddSkillsScreen(
                navController = navController,
                onComplete = {
                    navController.navigate("professional_experience") {
                        popUpTo("add_skills") { inclusive = true }
                    }
                }
            )
        }
        composable("professional_experience") {
            ProfessionalExperienceScreen(
                navController = navController,
                onComplete = {
                    navController.navigate("profile_setup") {
                        popUpTo("professional_experience") { inclusive = true }
                    }
                }
            )
        }
        composable("profile_setup") {
            ProfileSetupScreen(
                navController = navController,
                onComplete = {
                    navController.navigate("other_details") {
                        popUpTo("profile_setup") { inclusive = true }
                    }
                }
            )
        }
        composable("other_details") {
            OtherDetailsScreen(
                navController = navController,
                onComplete = {
                    navController.navigate("profile") {
                        popUpTo("other_details") { inclusive = true }
                    }
                }
            )
        }
        composable("profile") {
            profileViewModel.userProfile.value?.let { profile ->
                ProfilePage(
                    userProfile = profile,
                    onBackClick = { /* Disable back navigation from profile */ }
                )
            }
        }
    }
}