package com.example.udyothvi

import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.rememberAsyncImagePainter
import com.example.udyothvi.model.UserProfile
import com.example.udyothvi.model.Experience

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfilePage(
    userProfile: UserProfile,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .verticalScroll(scrollState)
    ) {
        // Top App Bar with back button and search
        TopAppBar(
            title = { Text(text = userProfile.fullName) },
            navigationIcon = {
                IconButton(onClick = onBackClick) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            },
            actions = {
                IconButton(onClick = { /* Handle search */ }) {
                    Icon(Icons.Default.Search, contentDescription = "Search")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.White,
                titleContentColor = Color.Black,
                navigationIconContentColor = Color.Black,
                actionIconContentColor = Color.Black
            )
        )

        // Cover Image and Profile Section
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
        ) {
            // Cover Image
            userProfile.coverImage?.let { coverUri ->
                Image(
                    painter = rememberAsyncImagePainter(coverUri),
                    contentDescription = "Cover Image",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }

            // Profile Image
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .align(Alignment.BottomStart)
                    .padding(16.dp)
            ) {
                userProfile.profileImage?.let { profileUri ->
                    Image(
                        painter = rememberAsyncImagePainter(profileUri),
                        contentDescription = "Profile Picture",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } ?: Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "Profile Picture",
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.LightGray),
                    tint = Color.White
                )
            }

            // Notification Bell
            IconButton(
                onClick = { /* Handle notifications */ },
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Notifications,
                    contentDescription = "Notifications",
                    tint = Color.Gray
                )
            }
        }

        // Profile Information
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = userProfile.fullName,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "${userProfile.title} at ${userProfile.company}",
                fontSize = 16.sp,
                color = Color.Black,
                modifier = Modifier.padding(top = 4.dp)
            )

            Text(
                text = userProfile.education,
                fontSize = 14.sp,
                color = Color.Gray,
                modifier = Modifier.padding(top = 4.dp)
            )

            Text(
                text = userProfile.location,
                fontSize = 14.sp,
                color = Color.Gray,
                modifier = Modifier.padding(top = 4.dp)
            )

            if (!userProfile.about.isNullOrEmpty()) {
                Text(
                    text = "About",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                )
                Text(
                    text = userProfile.about,
                    fontSize = 14.sp,
                    color = Color.Black
                )
            }

            // Skills Section
            if (userProfile.skills.isNotEmpty()) {
                Text(
                    text = "Skills",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                )
                userProfile.skills.forEach { skill ->
                    Text(
                        text = "• $skill",
                        fontSize = 14.sp,
                        color = Color.Black,
                        modifier = Modifier.padding(start = 8.dp, top = 4.dp)
                    )
                }
            }

            // Experience Section
            if (userProfile.experiences.isNotEmpty()) {
                Text(
                    text = "Experience",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                )
                userProfile.experiences.forEach { experience ->
                    ExperienceItem(experience = experience)
                }
            }

            // Social Links
            if (!userProfile.linkedIn.isNullOrEmpty() || !userProfile.github.isNullOrEmpty() || !userProfile.twitter.isNullOrEmpty()) {
                Text(
                    text = "Social Profiles",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                )
                userProfile.linkedIn?.let { linkedin ->
                    Text(
                        text = "LinkedIn: $linkedin",
                        fontSize = 14.sp,
                        color = Color.Blue,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
                userProfile.github?.let { github ->
                    Text(
                        text = "GitHub: $github",
                        fontSize = 14.sp,
                        color = Color.Blue,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
                userProfile.twitter?.let { twitter ->
                    Text(
                        text = "Twitter: $twitter",
                        fontSize = 14.sp,
                        color = Color.Blue,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }

            // Languages
            if (userProfile.languages.isNotEmpty()) {
                Text(
                    text = "Languages",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                )
                Text(
                    text = userProfile.languages.joinToString(", "),
                    fontSize = 14.sp,
                    color = Color.Black
                )
            }

            // Interests
            if (userProfile.interests.isNotEmpty()) {
                Text(
                    text = "Interests",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                )
                Text(
                    text = userProfile.interests.joinToString(", "),
                    fontSize = 14.sp,
                    color = Color.Black
                )
            }
        }

        // Bottom Navigation
        NavigationBar(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.White),
            containerColor = Color.White
        ) {
            NavigationBarItem(
                icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                label = { Text("Home") },
                selected = false,
                onClick = { /* Handle home click */ }
            )
            NavigationBarItem(
                icon = { Icon(Icons.Default.Group, contentDescription = "My Network") },
                label = { Text("My Network") },
                selected = false,
                onClick = { /* Handle network click */ }
            )
            NavigationBarItem(
                icon = { Icon(Icons.Default.Add, contentDescription = "Post") },
                label = { Text("Post") },
                selected = false,
                onClick = { /* Handle post click */ }
            )
            NavigationBarItem(
                icon = { Icon(Icons.Default.Chat, contentDescription = "Chat") },
                label = { Text("Chat") },
                selected = false,
                onClick = { /* Handle chat click */ }
            )
            NavigationBarItem(
                icon = { Icon(Icons.Default.School, contentDescription = "Courses") },
                label = { Text("Courses") },
                selected = false,
                onClick = { /* Handle courses click */ }
            )
            NavigationBarItem(
                icon = { Icon(Icons.Default.Work, contentDescription = "Jobs") },
                label = { Text("Jobs") },
                selected = false,
                onClick = { /* Handle jobs click */ }
            )
        }
    }
}

@Composable
fun ExperienceItem(experience: Experience) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        Text(
            text = experience.title,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = experience.company,
            fontSize = 14.sp,
            color = Color.Black
        )
        Text(
            text = "${experience.startDate} - ${experience.endDate}",
            fontSize = 14.sp,
            color = Color.Gray
        )
        Text(
            text = experience.description,
            fontSize = 14.sp,
            color = Color.Black,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
} 