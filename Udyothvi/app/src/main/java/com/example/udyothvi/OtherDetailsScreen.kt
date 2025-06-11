package com.example.udyothvi

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OtherDetailsScreen(
    navController: NavController,
    onComplete: () -> Unit,
    viewModel: ProfileViewModel = viewModel()
) {
    var website by remember { mutableStateOf("") }
    var linkedIn by remember { mutableStateOf("") }
    var github by remember { mutableStateOf("") }
    var twitter by remember { mutableStateOf("") }
    var languages by remember { mutableStateOf("") }
    var interests by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Other Details",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 24.dp)
        )

        OutlinedTextField(
            value = website,
            onValueChange = { website = it },
            label = { Text("Personal Website") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            singleLine = true
        )

        OutlinedTextField(
            value = linkedIn,
            onValueChange = { linkedIn = it },
            label = { Text("LinkedIn Profile") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            singleLine = true
        )

        OutlinedTextField(
            value = github,
            onValueChange = { github = it },
            label = { Text("GitHub Profile") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            singleLine = true
        )

        OutlinedTextField(
            value = twitter,
            onValueChange = { twitter = it },
            label = { Text("Twitter Profile") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            singleLine = true
        )

        OutlinedTextField(
            value = languages,
            onValueChange = { languages = it },
            label = { Text("Languages (comma separated)") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            singleLine = true
        )

        OutlinedTextField(
            value = interests,
            onValueChange = { interests = it },
            label = { Text("Interests (comma separated)") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            singleLine = true
        )

        Spacer(modifier = Modifier.weight(1f))

        Button(
            onClick = {
                viewModel.userProfile.value?.let { currentProfile ->
                    viewModel.updateProfile(
                        fullName = currentProfile.fullName,
                        title = currentProfile.title,
                        company = currentProfile.company,
                        education = currentProfile.education,
                        location = currentProfile.location,
                        about = currentProfile.about,
                        website = website,
                        linkedIn = linkedIn,
                        github = github,
                        twitter = twitter,
                        languages = languages.split(",").map { it.trim() },
                        interests = interests.split(",").map { it.trim() },
                        profileImage = currentProfile.profileImage,
                        coverImage = currentProfile.coverImage
                    )
                }
                navController.navigate("profile") {
                    popUpTo("educationalQualification") { inclusive = true }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            shape = RoundedCornerShape(24.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2))
        ) {
            Text("Finish and View Profile", color = Color.White)
        }
    }
} 