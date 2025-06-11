package com.example.udyothvi.education.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.example.udyothvi.*
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun setupNavGraph(navController: NavHostController) {
    val viewModel: ProfileViewModel = viewModel()
    
    NavHost(
        navController = navController,
        startDestination = "educationalQualification"
    ) {
        composable("educationalQualification") {
            EducationalQualificationPageUI(navController)
        }
        
        composable("skillsAndMediaPage") {
            SkillsAndMediaPage(navController)
        }
        
        composable("professionalScreen") {
            ProfessionalScreen(
                onAddMore = {},
                onBack = { navController.popBackStack() },
                onSaveAndContinue = { 
                    navController.navigate("profileActivity") {
                        popUpTo("educationalQualification") { inclusive = true }
                    }
                },
                onSkip = { 
                    navController.navigate("profileActivity") {
                        popUpTo("educationalQualification") { inclusive = true }
                    }
                }
            )
        }
        
        composable("profileActivity") {
            ProfileScreen(
                onBack = { navController.popBackStack() },
                onSaveAndContinue = { visibility ->
                    navController.navigate("otherDetails") {
                        popUpTo("educationalQualification") { inclusive = true }
                    }
                },
                onSkip = {
                    navController.navigate("otherDetails") {
                        popUpTo("educationalQualification") { inclusive = true }
                    }
                }
            )
        }
        
        composable("otherDetails") {
            OtherDetailsScreen(
                navController = navController,
                onComplete = {
                    navController.navigate("profile") {
                        popUpTo("educationalQualification") { inclusive = true }
                    }
                }
            )
        }
        
        composable("profile") {
            viewModel.userProfile.value?.let { profile ->
                ProfilePage(
                    userProfile = profile,
                    onBackClick = { /* Disable back navigation */ }
                )
            }
        }
    }
}