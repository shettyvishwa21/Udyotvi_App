--
-- PostgreSQL database dump
--

-- Dumped from database version 17.3
-- Dumped by pg_dump version 17.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_change_password(bigint, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_change_password(ip_user_id bigint, ip_current_password character varying, ip_new_password character varying) RETURNS TABLE(result_message text, result_type integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_stored_password CHARACTER VARYING;
BEGIN
    -- Check if the user exists and is active
    SELECT password INTO v_stored_password
    FROM m_user
    WHERE id = ip_user_id AND is_active = TRUE;

    IF v_stored_password IS NULL THEN
        result_message := 'User not found or inactive';
        result_type := 0;
        RETURN NEXT;
        RETURN;
    END IF;

    -- Verify the current password
    IF v_stored_password != ip_current_password THEN
        result_message := 'Current password is incorrect';
        result_type := 0;
        RETURN NEXT;
        RETURN;
    END IF;

    -- Validate the new password (basic check, adjust as needed)
    IF ip_new_password IS NULL OR length(trim(ip_new_password)) < 6 THEN
        result_message := 'New password must be at least 6 characters long';
        result_type := 0;
        RETURN NEXT;
        RETURN;
    END IF;

    -- Update the password and reset is_reset
    UPDATE m_user
    SET 
        password = ip_new_password,
        is_reset = FALSE,
        updated_on = CURRENT_TIMESTAMP,
        updated_by = ip_user_id -- Self-update
    WHERE id = ip_user_id;

    -- Return success
    result_message := 'Password changed successfully';
    result_type := 1;
    RETURN NEXT;
END;
$$;


ALTER FUNCTION public.fn_change_password(ip_user_id bigint, ip_current_password character varying, ip_new_password character varying) OWNER TO postgres;

--
-- Name: fn_fetch_user_profile(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_fetch_user_profile(p_user_id bigint) RETURNS TABLE(resultmessage text, resulttype integer, resultdata jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_basic_profile JSONB;
    v_jobs JSONB;
    v_courses JSONB;
    v_education JSONB;
    v_experience JSONB;
    v_posts JSONB;
BEGIN
    -- Fetch Basic Profile
    SELECT JSONB_BUILD_OBJECT(
        'FirstName', u.first_name,
        'LastName', u.last_name,
        'Email', u.email,
        'PhoneNumber', u.phone_number,
        'AccountType', COALESCE(at.account_type, 'Unknown'),
        'Gender', CASE
            WHEN u.gender = 1 THEN 'Male'
            WHEN u.gender = 2 THEN 'Female'
            WHEN u.gender = 3 THEN 'Other'
            ELSE 'Unknown'
        END,
        'ProfilePic', u.profile_pic,
        'Bio', u.bio,
        'Location', u.location,
        'SocialLink', u.social_link,
        'CreatedOn', u.created_on,
        'IsActive', u.is_active
    ) INTO v_basic_profile
    FROM m_user u
    LEFT JOIN m_account_type at ON u.account_type = at.id
    WHERE u.id = p_user_id;

    IF v_basic_profile IS NULL THEN
        RETURN QUERY
        SELECT 'Profile fetch failed: User not found'::TEXT, 0::INTEGER, NULL::JSONB;
        RETURN;
    END IF;

    -- Fetch Jobs (Updated)
   -- Fetch Jobs
SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
        'CompanyName', COALESCE(o.organisation_name, 'Unknown'),
        'DesignationName', COALESCE(d.designation, 'Unknown'),
        'Description', j.description,
        'Requirement', j.requirement,
        'Location', j.location,
        'JobType', CASE
           WHEN j.job_type = 1 THEN 'Full-time'
           WHEN j.job_type = 2 THEN 'Part-time'
           WHEN j.job_type = 3 THEN 'Internship'
           ELSE 'Unknown'
           END,
        'JobMode', CASE
            WHEN j.job_mode = 1 THEN 'Remote'
            WHEN j.job_mode = 2 THEN 'Onsite'
            WHEN j.job_mode = 3 THEN 'Hybrid'
            ELSE 'Unknown'
        END,
        'Hashtags', CASE
            WHEN j.hashtags IS NOT NULL THEN ARRAY_TO_JSON(STRING_TO_ARRAY(j.hashtags, ','))::JSONB
            ELSE '[]'::JSONB
        END,
        'PayCurrency', COALESCE(cur.currency_code, 'Unknown'),
        'PayStartRange', j.pay_start_range,
        'PayEndRange', j.pay_end_range,
        'OpeningDate', j.opening_date,
        'ClosingDate', j.closing_date,
        'CreatedOn', j.created_on
    )
) INTO v_jobs
FROM m_job j
JOIN t_job_mapping jm ON j.id = jm.job_id
LEFT JOIN m_organisation o ON j.organisation_id = o.id
LEFT JOIN m_designations d ON j.designation_id = d.id
LEFT JOIN m_currency cur ON j.pay_currency = cur.id
WHERE jm.posted_by = p_user_id;

    -- Fetch Courses
    SELECT JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'CourseName', c.course_name,
            'CourseType', COALESCE(ct.course_type, 'Unknown'),
            'Level', COALESCE(cl."level", 'Unknown'),
            'SubscriptionType', COALESCE(st."type_name", 'Unknown'),
            'Status', COALESCE(cs."status_name", 'Unknown'),
            'CourseThumbnail', c.course_thumbnail,
            'CourseBanner', c.course_banner,
            'CertificationAvailable', c.certification_available,
            'Description', c.description,
            'Cost', c.cost,
            'PreviewVideoUrl', c.preview_video_url,
            'CreatedOn', c.created_on,
            'ValidFrom', cm.valid_from,
            'ValidTo', cm.valid_to
        )
    ) INTO v_courses
    FROM m_course c
    JOIN m_course_mapping cm ON c.id = cm.course_id
    LEFT JOIN m_course_type ct ON c.course_type = ct.id
    LEFT JOIN m_course_level cl ON c.level = cl.id
    LEFT JOIN m_subscription_type st ON c.subscription_type = st.id
    LEFT JOIN m_course_status cs ON c.status = cs.id
    WHERE cm.user_id = p_user_id;

    -- Fetch Education
    SELECT JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'EducationLevel', e.education_level,
            'Organisation', e.organisation,
            'StartDate', e.start_date,
            'EndDate', e.end_date
        )
    ) INTO v_education
    FROM m_education e
    JOIN t_education_mapping em ON e.id = em.education_id
    WHERE em.user_id = p_user_id;

    -- Fetch Experience (Unchanged from your original function)
    SELECT JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'CompanyName', COALESCE(c.company_name, 'Unknown'),
            'DesignationName', COALESCE(d.designation, 'Unknown'),
            'StartDate', ue.start_date,
            'EndDate', ue.end_date,
            'CurrentlyPursuing', ue.currently_pursuing
        )
    ) INTO v_experience
    FROM t_user_experience ue
    LEFT JOIN m_companies c ON ue.company_id = c.id
    LEFT JOIN m_designations d ON ue.designation_id = d.id
    WHERE ue.user_id = p_user_id;

    -- Fetch Posts
    SELECT JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'Content', p.content,
            'MediaUrl', p.media_url,
            'Hashtags', CASE
                WHEN p.hashtags IS NOT NULL THEN ARRAY_TO_JSON(STRING_TO_ARRAY(p.hashtags, ','))::JSONB
                ELSE '[]'::JSONB
            END,
            'PostVisibility', p.post_visibility,
            'CreatedOn', p.created_on
        )
    ) INTO v_posts
    FROM m_post p
    JOIN t_post_tracking pt ON p.id = pt.post_id
    WHERE pt.posted_by = p_user_id;

    -- Combine all sections into resultdata
    RETURN QUERY
    SELECT
        'Profile fetch successful'::TEXT,
        1::INTEGER,
        JSONB_BUILD_OBJECT(
            'ResultMessage', 'Profile fetch successful',
            'ResultType', 1,
            'ProfileData', JSONB_BUILD_OBJECT(
                'BasicProfile', v_basic_profile,
                'Jobs', COALESCE(v_jobs, '[]'::JSONB),
                'Courses', COALESCE(v_courses, '[]'::JSONB),
                'Education', COALESCE(v_education, '[]'::JSONB),
                'Experience', COALESCE(v_experience, '[]'::JSONB),
                'Posts', COALESCE(v_posts, '[]'::JSONB)
            )
        )::JSONB;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY
    SELECT ('Database error: ' || SQLERRM)::TEXT, 0::INTEGER, NULL::JSONB;
END;
$$;


ALTER FUNCTION public.fn_fetch_user_profile(p_user_id bigint) OWNER TO postgres;

--
-- Name: fn_get_user_details(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_get_user_details(ip_id bigint) RETURNS TABLE(user_id bigint, first_name character varying, last_name character varying, user_name character varying, phone_number character varying, email character varying, gender character varying, user_type character varying, is_active boolean, is_deleted boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id AS user_id,
        u.first_name,
        u.last_name,
        u.user_name,
        u.phone_number,
        u.email,
        g.gender AS gender,
        ut.user_type AS user_type,
        u.is_active,
        u.is_delete AS is_deleted
    FROM m_user u
    INNER JOIN m_gender g ON u.gender = g.id
    INNER JOIN m_user_type ut ON u.user_type = ut.id
    WHERE u.id = ip_id;
END;
$$;


ALTER FUNCTION public.fn_get_user_details(ip_id bigint) OWNER TO postgres;

--
-- Name: fn_m_organisation_insert_update(bigint, bigint, bigint, character varying, character varying, character varying, character varying, text, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_m_organisation_insert_update(ip_id bigint, ip_industry_id bigint, ip_pay_currency bigint, ip_email character varying, ip_contact_number character varying, ip_organisation_name character varying, ip_address character varying, ip_description text, ip_banner_url character varying, ip_logo_url character varying, ip_social_link character varying, ip_website_link character varying) RETURNS TABLE(resulttype integer, resultmessage text, orgid bigint)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_orgid BIGINT;
BEGIN
    -- Basic input validation
    IF ip_organisation_name IS NULL OR TRIM(ip_organisation_name) = '' THEN
        RETURN QUERY SELECT 6, 'Organisation name cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    IF ip_industry_id IS NULL THEN
        RETURN QUERY SELECT 7, 'Industry ID cannot be null', NULL::bigint;
        RETURN;
    END IF;

    IF ip_pay_currency IS NULL THEN
        RETURN QUERY SELECT 8, 'Pay currency ID cannot be null', NULL::bigint;
        RETURN;
    END IF;

    -- Email format validation (if provided)
    IF ip_email IS NOT NULL AND TRIM(ip_email) != '' THEN
        IF ip_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            RETURN QUERY SELECT 11, 'Invalid email format', NULL::bigint;
            RETURN;
        END IF;
    END IF;

    -- Phone number format validation (if provided)
    IF ip_contact_number IS NOT NULL AND TRIM(ip_contact_number) != '' THEN
        IF ip_contact_number !~ '^\+[0-9]{1,4}[0-9]{6,14}$' THEN
            RETURN QUERY SELECT 13, 'Invalid contact number format', NULL::bigint;
            RETURN;
        END IF;
    END IF;

    -- INSERT case (ip_id = 0)
    IF ip_id = 0 THEN
        -- Check for existing organisation name
        IF EXISTS (SELECT 1 FROM m_organisation WHERE organisation_name = TRIM(ip_organisation_name)) THEN
            RETURN QUERY SELECT 3, 'Organisation name already exists', NULL::bigint;
            RETURN;
        END IF;

        -- Check for existing email (if provided)
        IF ip_email IS NOT NULL AND TRIM(ip_email) != '' THEN
            IF EXISTS (SELECT 1 FROM m_organisation WHERE email = TRIM(ip_email)) THEN
                RETURN QUERY SELECT 4, 'Email already exists', NULL::bigint;
                RETURN;
            END IF;
        END IF;

        -- Perform INSERT (id will be auto-generated)
        INSERT INTO m_organisation (
            industry_id, pay_currency, email, contact_number, organisation_name,
            address, description, banner_url, logo_url, social_link,
            website_link, created_on, updated_on
        ) VALUES (
            ip_industry_id,
            ip_pay_currency,
            NULLIF(TRIM(ip_email), ''),
            NULLIF(TRIM(ip_contact_number), ''),
            TRIM(ip_organisation_name),
            NULLIF(TRIM(ip_address), ''),
            NULLIF(TRIM(ip_description), ''),
            NULLIF(TRIM(ip_banner_url), ''),
            NULLIF(TRIM(ip_logo_url), ''),
            NULLIF(TRIM(ip_social_link), ''),
            NULLIF(TRIM(ip_website_link), ''),
            NOW(),
            NOW()
        )
        RETURNING id INTO v_orgid;

        RETURN QUERY SELECT 0, 'Organisation inserted successfully', v_orgid;

    -- UPDATE case (ip_id > 0)
    ELSIF ip_id > 0 THEN
        -- Check if organisation exists
        IF NOT EXISTS (SELECT 1 FROM m_organisation WHERE id = ip_id) THEN
            RETURN QUERY SELECT 5, 'Organisation not found', NULL::bigint;
            RETURN;
        END IF;

        -- Check for organisation name conflict (excluding current record)
        IF EXISTS (SELECT 1 FROM m_organisation WHERE organisation_name = TRIM(ip_organisation_name) AND id <> ip_id) THEN
            RETURN QUERY SELECT 3, 'Organisation name already exists', NULL::bigint;
            RETURN;
        END IF;

        -- Check for email conflict (excluding current record)
        IF ip_email IS NOT NULL AND TRIM(ip_email) != '' THEN
            IF EXISTS (SELECT 1 FROM m_organisation WHERE email = TRIM(ip_email) AND id <> ip_id) THEN
                RETURN QUERY SELECT 4, 'Email already exists', NULL::bigint;
                RETURN;
            END IF;
        END IF;

        -- Perform UPDATE
        UPDATE m_organisation
        SET industry_id = ip_industry_id,
            pay_currency = ip_pay_currency,
            email = NULLIF(TRIM(ip_email), ''),
            contact_number = NULLIF(TRIM(ip_contact_number), ''),
            organisation_name = TRIM(ip_organisation_name),
            address = NULLIF(TRIM(ip_address), ''),
            description = NULLIF(TRIM(ip_description), ''),
            banner_url = NULLIF(TRIM(ip_banner_url), ''),
            logo_url = NULLIF(TRIM(ip_logo_url), ''),
            social_link = NULLIF(TRIM(ip_social_link), ''),
            website_link = NULLIF(TRIM(ip_website_link), ''),
            updated_on = NOW()
        WHERE id = ip_id
        RETURNING id INTO v_orgid;

        RETURN QUERY SELECT 1, 'Organisation updated successfully', v_orgid;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 99, 'An error occurred: ' || SQLERRM, NULL::bigint;
END;
$_$;


ALTER FUNCTION public.fn_m_organisation_insert_update(ip_id bigint, ip_industry_id bigint, ip_pay_currency bigint, ip_email character varying, ip_contact_number character varying, ip_organisation_name character varying, ip_address character varying, ip_description text, ip_banner_url character varying, ip_logo_url character varying, ip_social_link character varying, ip_website_link character varying) OWNER TO postgres;

--
-- Name: fn_m_user_insert_update(bigint, character varying, character varying, character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, bigint, boolean, boolean, boolean, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_m_user_insert_update(ip_id bigint, ip_first_name character varying, ip_last_name character varying, ip_phone_number character varying, ip_email character varying, ip_password character varying, ip_account_type integer, ip_gender integer, ip_profile_pic character varying, ip_bio character varying, ip_location character varying, ip_created_by bigint DEFAULT NULL::bigint, ip_is_active boolean DEFAULT true, ip_is_deleted boolean DEFAULT false, ip_is_sso_user boolean DEFAULT false, ip_social_link character varying DEFAULT NULL::character varying) RETURNS TABLE(resulttype integer, resultmessage text, userid bigint)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_userid BIGINT;
BEGIN
    -- Basic input validation
    IF ip_first_name IS NULL OR TRIM(ip_first_name) = '' THEN
        RETURN QUERY SELECT 6, 'First name cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    IF ip_last_name IS NULL OR TRIM(ip_last_name) = '' THEN
        RETURN QUERY SELECT 9, 'Last name cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    IF ip_email IS NULL OR TRIM(ip_email) = '' THEN
        RETURN QUERY SELECT 7, 'Email cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    -- Email format validation
    IF ip_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RETURN QUERY SELECT 11, 'Invalid email format', NULL::bigint;
        RETURN;
    END IF;

    -- Validate phone number format (e.g., starts with country code like +91)
    IF ip_phone_number IS NOT NULL AND TRIM(ip_phone_number) != '' THEN
        IF ip_phone_number !~ '^\+[0-9]{1,4}[0-9]{6,14}$' THEN
            RETURN QUERY SELECT 13, 'Invalid phone number format', NULL::bigint;
            RETURN;
        END IF;
    END IF;

    -- Gender validation (assuming 1 = Male, 2 = Female)
    IF ip_gender NOT IN (1, 2) THEN
        RETURN QUERY SELECT 14, 'Invalid gender value', NULL::bigint;
        RETURN;
    END IF;

    -- INSERT case (ip_id = 0)
    IF ip_id = 0 THEN
        -- Check for existing email
        IF EXISTS (SELECT 1 FROM m_user WHERE email = TRIM(ip_email)) THEN
            RETURN QUERY SELECT 3, 'Email already exists', NULL::bigint;
            RETURN;
        END IF;

        -- Check for existing phone number (only if provided)
        IF ip_phone_number IS NOT NULL AND TRIM(ip_phone_number) != '' THEN
            IF EXISTS (SELECT 1 FROM m_user WHERE phone_number = TRIM(ip_phone_number)) THEN
                RETURN QUERY SELECT 8, 'Phone number already exists', NULL::bigint;
                RETURN;
            END IF;
        END IF;

        -- Perform INSERT (store password as-is, since API handles password logic)
        INSERT INTO m_user (
            first_name, last_name, phone_number, email, password,
            account_type, gender, profile_pic, bio, location,
            created_on, created_by, updated_on, updated_by,
            is_active, is_deleted, is_sso_user, social_link
        ) VALUES (
            NULLIF(TRIM(ip_first_name), ''),
            NULLIF(TRIM(ip_last_name), ''),
            NULLIF(TRIM(ip_phone_number), ''),
            TRIM(ip_email),
            NULLIF(TRIM(ip_password), ''), -- Store password as-is
            ip_account_type,
            ip_gender,
            NULLIF(TRIM(ip_profile_pic), ''),
            NULLIF(TRIM(ip_bio), ''),
            NULLIF(TRIM(ip_location), ''),
            NOW(),
            ip_created_by,
            NOW(),
            ip_created_by,
            ip_is_active,
            ip_is_deleted,
            ip_is_sso_user,
            NULLIF(TRIM(ip_social_link), '')
        )
        RETURNING id INTO v_userid;

        RETURN QUERY SELECT 0, 'User inserted successfully', v_userid;

    -- UPDATE case (ip_id > 0)
    ELSIF ip_id > 0 THEN
        -- Check if user exists
        IF NOT EXISTS (SELECT 1 FROM m_user WHERE id = ip_id) THEN
            RETURN QUERY SELECT 4, 'User not found', NULL::bigint;
            RETURN;
        END IF;

        -- Check for email conflict (excluding current user)
        IF EXISTS (SELECT 1 FROM m_user WHERE email = TRIM(ip_email) AND id <> ip_id) THEN
            RETURN QUERY SELECT 3, 'Email already exists', NULL::bigint;
            RETURN;
        END IF;

        -- Check for phone number conflict (excluding current user)
        IF ip_phone_number IS NOT NULL AND TRIM(ip_phone_number) != '' THEN
            IF EXISTS (SELECT 1 FROM m_user WHERE phone_number = TRIM(ip_phone_number) AND id <> ip_id) THEN
                RETURN QUERY SELECT 8, 'Phone number already exists', NULL::bigint;
                RETURN;
            END IF;
        END IF;

        -- Perform UPDATE (store password as-is, since API handles password logic)
        UPDATE m_user
        SET first_name = NULLIF(TRIM(ip_first_name), ''),
            last_name = NULLIF(TRIM(ip_last_name), ''),
            phone_number = NULLIF(TRIM(ip_phone_number), ''),
            email = TRIM(ip_email),
            password = CASE 
                          WHEN ip_password IS NOT NULL AND TRIM(ip_password) != '' 
                          THEN NULLIF(TRIM(ip_password), '') 
                          ELSE password 
                       END, -- Store password as-is
            account_type = ip_account_type,
            gender = ip_gender,
            profile_pic = NULLIF(TRIM(ip_profile_pic), ''),
            bio = NULLIF(TRIM(ip_bio), ''),
            location = NULLIF(TRIM(ip_location), ''),
            updated_on = NOW(),
            updated_by = ip_created_by,
            is_active = ip_is_active,
            is_deleted = ip_is_deleted,
            is_sso_user = ip_is_sso_user,
            social_link = NULLIF(TRIM(ip_social_link), '')
        WHERE id = ip_id
        RETURNING id INTO v_userid;

        RETURN QUERY SELECT 1, 'User updated successfully', v_userid;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 99, 'An error occurred: ' || SQLERRM, NULL::bigint;
END;
$_$;


ALTER FUNCTION public.fn_m_user_insert_update(ip_id bigint, ip_first_name character varying, ip_last_name character varying, ip_phone_number character varying, ip_email character varying, ip_password character varying, ip_account_type integer, ip_gender integer, ip_profile_pic character varying, ip_bio character varying, ip_location character varying, ip_created_by bigint, ip_is_active boolean, ip_is_deleted boolean, ip_is_sso_user boolean, ip_social_link character varying) OWNER TO postgres;

--
-- Name: fn_m_user_register(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_m_user_register(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender integer) RETURNS TABLE(resulttype integer, resultmessage text, userid bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_userid BIGINT;
BEGIN
    -- Input validations
    IF ip_first_name IS NULL OR TRIM(ip_first_name) = '' THEN
        RETURN QUERY SELECT 6, 'First name cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    IF ip_last_name IS NULL OR TRIM(ip_last_name) = '' THEN
        RETURN QUERY SELECT 9, 'Last name cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    IF ip_email IS NULL OR TRIM(ip_email) = '' THEN
        RETURN QUERY SELECT 7, 'Email cannot be empty', NULL::bigint;
        RETURN;
    END IF;

    -- Check for existing email
    IF EXISTS (SELECT 1 FROM m_user WHERE email = TRIM(ip_email)) THEN
        RETURN QUERY SELECT 3, 'Email already exists', NULL::bigint;
        RETURN;
    END IF;

    -- Check for existing phone number (if provided)
    IF ip_phone_number IS NOT NULL AND TRIM(ip_phone_number) != '' THEN
        IF EXISTS (SELECT 1 FROM m_user WHERE phone_number = TRIM(ip_phone_number)) THEN
            RETURN QUERY SELECT 8, 'Phone number already exists', NULL::bigint;
            RETURN;
        END IF;
    END IF;

    -- Perform INSERT
    INSERT INTO m_user (
        first_name,
        last_name,
        email,
        phone_number,
        gender,
        account_type,
        created_on,
        created_by,
        updated_on,
        updated_by,
        is_active,
        is_deleted,
        is_sso_user
    ) VALUES (
        NULLIF(TRIM(ip_first_name), ''),
        NULLIF(TRIM(ip_last_name), ''),
        TRIM(ip_email),
        NULLIF(TRIM(ip_phone_number), ''),
        ip_gender,
        1, -- Default account_type (e.g., 1 for regular user)
        NOW(),
        0, -- Default created_by (e.g., 0 for system)
        NOW(),
        0, -- Default updated_by
        true, -- Default is_active
        false, -- Default is_deleted
        false -- Default is_sso_user
    )
    RETURNING id INTO v_userid;

    RETURN QUERY SELECT 0, 'User registered successfully', v_userid;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 99, 'An error occurred: ' || SQLERRM, NULL::bigint;
END;
$$;


ALTER FUNCTION public.fn_m_user_register(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender integer) OWNER TO postgres;

--
-- Name: fn_register_user(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_register_user(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender character varying) RETURNS TABLE(account_id bigint, first_name character varying, last_name character varying, email character varying, phone_number character varying, gender smallint, resultmessage character varying, resulttype integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_existing_user RECORD;
    v_existing_phone RECORD;
    v_gender_id SMALLINT;
    v_default_password character varying;
    v_new_id BIGINT;
BEGIN
    RAISE NOTICE 'Starting function with inputs: %, %, %, %, %', ip_first_name, ip_last_name, ip_email, ip_phone_number, ip_gender;

    -- Validate input
    IF ip_first_name IS NULL OR TRIM(ip_first_name) = '' THEN
        RAISE NOTICE 'Validation failed: First name is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'First name is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_last_name IS NULL OR TRIM(ip_last_name) = '' THEN
        RAISE NOTICE 'Validation failed: Last name is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Last name is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_email IS NULL OR TRIM(ip_email) = '' THEN
        RAISE NOTICE 'Validation failed: Email is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Email is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_phone_number IS NULL OR TRIM(ip_phone_number) = '' THEN
        RAISE NOTICE 'Validation failed: Phone number is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Phone number is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_gender IS NULL OR TRIM(ip_gender) = '' THEN
        RAISE NOTICE 'Validation failed: Gender is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Gender is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Check for duplicate email with qualified column name
    SELECT id INTO v_existing_user
    FROM public.m_user
    WHERE LOWER(TRIM(public.m_user.email)) = LOWER(TRIM(ip_email))
    LIMIT 1;

    IF v_existing_user IS NOT NULL THEN
        RAISE NOTICE 'Validation failed: Email already registered: %', ip_email;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Email already registered'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Check for duplicate phone number
    SELECT id INTO v_existing_phone
    FROM public.m_user
    WHERE TRIM(public.m_user.phone_number) = TRIM(ip_phone_number)
    LIMIT 1;

    IF v_existing_phone IS NOT NULL THEN
        RAISE NOTICE 'Validation failed: Phone number already registered: %', ip_phone_number;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Phone number already registered'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Map gender to gender_id with qualified table name
    SELECT id INTO v_gender_id
    FROM public.m_gender
    WHERE LOWER(TRIM(public.m_gender.gender)) = LOWER(TRIM(ip_gender))
    LIMIT 1;

    IF v_gender_id IS NULL THEN
        RAISE NOTICE 'Validation failed: Invalid gender value %', ip_gender;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Invalid gender value'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    RAISE NOTICE 'Gender ID mapped: % for gender %', v_gender_id, ip_gender;

    -- Generate a default random password
    v_default_password := substring(md5(random()::text), 1, 8);
    RAISE NOTICE 'Generated password: %', v_default_password;

    -- Insert new user with account_type
    INSERT INTO public.m_user (
        first_name, last_name, email, phone_number, gender, password,
        is_reset, is_deleted, is_active, created_on, updated_on, account_type
    )
    VALUES (
        TRIM(ip_first_name),
        TRIM(ip_last_name),
        LOWER(TRIM(ip_email)),
        TRIM(ip_phone_number),
        v_gender_id,
        v_default_password,
        FALSE,
        FALSE,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        1
    )
    RETURNING id INTO v_new_id;

    RAISE NOTICE 'User inserted with ID: %', v_new_id;

    -- Return success
    RETURN QUERY SELECT
        v_new_id,
        TRIM(ip_first_name)::VARCHAR,
        TRIM(ip_last_name)::VARCHAR,
        LOWER(TRIM(ip_email))::VARCHAR,
        TRIM(ip_phone_number)::VARCHAR,
        v_gender_id,
        ('User registered successfully. Default password: ' || v_default_password)::VARCHAR,
        1::bigint;

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique violation occurred: %', SQLERRM;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key violation occurred: %', SQLERRM;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected exception occurred: %', SQLERRM;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
END;
$$;


ALTER FUNCTION public.fn_register_user(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender character varying) OWNER TO postgres;

--
-- Name: fn_register_user(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_register_user(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender character varying, ip_account_type integer DEFAULT 1) RETURNS TABLE(account_id bigint, first_name character varying, last_name character varying, email character varying, phone_number character varying, gender smallint, resultmessage character varying, resulttype integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_existing_user RECORD;
    v_existing_phone RECORD;
    v_gender_id SMALLINT;
    v_default_password character varying;
    v_new_id BIGINT;
BEGIN
    RAISE NOTICE 'Starting function with inputs: %, %, %, %, %, %', ip_first_name, ip_last_name, ip_email, ip_phone_number, ip_gender, ip_account_type;

    -- Validate input
    IF ip_first_name IS NULL OR TRIM(ip_first_name) = '' THEN
        RAISE NOTICE 'Validation failed: First name is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'First name is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_last_name IS NULL OR TRIM(ip_last_name) = '' THEN
        RAISE NOTICE 'Validation failed: Last name is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Last name is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_email IS NULL OR TRIM(ip_email) = '' THEN
        RAISE NOTICE 'Validation failed: Email is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Email is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_phone_number IS NULL OR TRIM(ip_phone_number) = '' THEN
        RAISE NOTICE 'Validation failed: Phone number is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Phone number is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    IF ip_gender IS NULL OR TRIM(ip_gender) = '' THEN
        RAISE NOTICE 'Validation failed: Gender is required';
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Gender is required'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Validate account_type (if it’s a foreign key)
    IF ip_account_type IS NOT NULL THEN
        PERFORM 1 FROM public.account_types WHERE id = ip_account_type;
        IF NOT FOUND THEN
            RAISE NOTICE 'Validation failed: Invalid account type %', ip_account_type;
            RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Invalid account type'::VARCHAR, 0::INTEGER;
            RETURN;
        END IF;
    END IF;

    -- Check for duplicate email with qualified column name
    SELECT id INTO v_existing_user
    FROM public.m_user
    WHERE LOWER(TRIM(public.m_user.email)) = LOWER(TRIM(ip_email))
    LIMIT 1;

    IF v_existing_user IS NOT NULL THEN
        RAISE NOTICE 'Validation failed: Email already registered: %', ip_email;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Email already registered'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Check for duplicate phone number
    SELECT id INTO v_existing_phone
    FROM public.m_user
    WHERE TRIM(public.m_user.phone_number) = TRIM(ip_phone_number)
    LIMIT 1;

    IF v_existing_phone IS NOT NULL THEN
        RAISE NOTICE 'Validation failed: Phone number already registered: %', ip_phone_number;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Phone number already registered'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Map gender to gender_id with qualified table name
    SELECT id INTO v_gender_id
    FROM public.m_gender
    WHERE LOWER(TRIM(public.m_gender.gender)) = LOWER(TRIM(ip_gender))
    LIMIT 1;

    IF v_gender_id IS NULL THEN
        RAISE NOTICE 'Validation failed: Invalid gender value %', ip_gender;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Invalid gender value'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    RAISE NOTICE 'Gender ID mapped: % for gender %', v_gender_id, ip_gender;

    -- Generate a default random password
    v_default_password := substring(md5(random()::text), 1, 8);
    RAISE NOTICE 'Generated password: %', v_default_password;

    -- Insert new user with account_type
    INSERT INTO public.m_user (
        first_name, last_name, email, phone_number, gender, password,
        is_reset, is_deleted, is_active, created_on, updated_on, account_type
    )
    VALUES (
        TRIM(ip_first_name),
        TRIM(ip_last_name),
        LOWER(TRIM(ip_email)),
        TRIM(ip_phone_number),
        v_gender_id,
        v_default_password,
        FALSE,
        FALSE,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        ip_account_type
    )
    RETURNING id INTO v_new_id;

    RAISE NOTICE 'User inserted with ID: %', v_new_id;

    -- Return success
    RETURN QUERY SELECT
        v_new_id,
        TRIM(ip_first_name)::VARCHAR,
        TRIM(ip_last_name)::VARCHAR,
        LOWER(TRIM(ip_email))::VARCHAR,
        TRIM(ip_phone_number)::VARCHAR,
        v_gender_id,
        ('User registered successfully. Default password: ' || v_default_password)::VARCHAR,
        1::INTEGER;

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique violation occurred: %', SQLERRM;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key violation occurred: %', SQLERRM;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected exception occurred: %', SQLERRM;
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
END;
$$;


ALTER FUNCTION public.fn_register_user(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender character varying, ip_account_type integer) OWNER TO postgres;

--
-- Name: fn_register_user(character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_register_user(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender character varying, ip_password character varying) RETURNS TABLE(account_id bigint, first_name character varying, last_name character varying, email character varying, phone_number character varying, gender smallint, resultmessage character varying, resulttype integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_existing_user RECORD;
    v_existing_phone RECORD;
    v_gender_id SMALLINT;
    v_new_id BIGINT;
BEGIN
    -- ... validation code unchanged ...

    -- Map gender to gender_id with qualified table name
    SELECT id INTO v_gender_id
    FROM public.m_gender
    WHERE LOWER(TRIM(public.m_gender.gender)) = LOWER(TRIM(ip_gender))
    LIMIT 1;

    IF v_gender_id IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, 'Invalid gender value'::VARCHAR, 0::INTEGER;
        RETURN;
    END IF;

    -- Insert new user with hashed password
    INSERT INTO public.m_user (
        first_name, last_name, email, phone_number, gender, password,
        is_reset, is_deleted, is_active, created_on, updated_on
    )
    VALUES (
        TRIM(ip_first_name),
        TRIM(ip_last_name),
        LOWER(TRIM(ip_email)),
        TRIM(ip_phone_number),
        v_gender_id,
        ip_password, -- store the hashed password
        FALSE,
        FALSE,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_new_id;

    -- Return success
    RETURN QUERY SELECT
        v_new_id,
        TRIM(ip_first_name)::VARCHAR,
        TRIM(ip_last_name)::VARCHAR,
        LOWER(TRIM(ip_email))::VARCHAR,
        TRIM(ip_phone_number)::VARCHAR,
        v_gender_id,
        'User registered successfully.'::VARCHAR,
        1::INTEGER;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
    WHEN foreign_key_violation THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
    WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::VARCHAR, NULL::SMALLINT, ('Registration failed: ' || SQLERRM)::VARCHAR, 0::INTEGER;
END;
$$;


ALTER FUNCTION public.fn_register_user(ip_first_name character varying, ip_last_name character varying, ip_email character varying, ip_phone_number character varying, ip_gender character varying, ip_password character varying) OWNER TO postgres;

--
-- Name: fn_update_user_profile(bigint, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_update_user_profile(p_user_id bigint, p_profile_data jsonb) RETURNS TABLE(resultmessage text, resulttype integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_basic_profile jsonb;
    v_education_array jsonb;
    v_experience_array jsonb;
    v_education jsonb;
    v_experience jsonb;
    v_education_id bigint;
    v_experience_id bigint;
    v_is_new boolean;
    v_index integer;
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (SELECT 1 FROM m_user WHERE id = p_user_id) THEN
        RETURN QUERY
        SELECT 'User not found'::text, 0::integer;
        RETURN;
    END IF;

    -- Start a transaction
    BEGIN
        -- Extract the sections from the input JSONB
        v_basic_profile := p_profile_data->'basicProfile';
        v_education_array := p_profile_data->'education';
        v_experience_array := p_profile_data->'experience';

        -- Update Basic Profile if provided (only specific fields)
        IF v_basic_profile IS NOT NULL THEN
            UPDATE m_user
            SET
                first_name = (v_basic_profile->>'firstName')::text,
                last_name = (v_basic_profile->>'lastName')::text,
                email = (v_basic_profile->>'email')::text,
                phone_number = (v_basic_profile->>'phoneNumber')::text,
                profile_pic = (v_basic_profile->>'profilePic')::text,
                bio = (v_basic_profile->>'bio')::text,
                location = (v_basic_profile->>'location')::text,
                social_link = (v_basic_profile->>'socialLink')::text
            WHERE id = p_user_id;
        END IF;

        -- Update or insert Education entries if provided
        IF v_education_array IS NOT NULL AND jsonb_array_length(v_education_array) > 0 THEN
            FOR v_index IN 0..(jsonb_array_length(v_education_array) - 1)
            LOOP
                v_education := v_education_array->v_index;
                v_is_new := (v_education->>'isNew')::boolean;

                IF v_is_new THEN
                    -- Insert new education record
                    INSERT INTO m_education (
                        education_level,
                        organisation,
                        start_date,
                        end_date
                    )
                    VALUES (
                        (v_education->>'educationLevel')::text,
                        (v_education->>'organisation')::text,
                        (v_education->>'startDate')::timestamp,
                        CASE
                            WHEN v_education->>'endDate' IS NULL THEN NULL
                            ELSE (v_education->>'endDate')::timestamp
                        END
                    )
                    RETURNING id INTO v_education_id;

                    -- Link the new education record to the user
                    INSERT INTO t_education_mapping (user_id, education_id)
                    VALUES (p_user_id, v_education_id);
                ELSE
                    -- Find the education record to update by matching fields
                    SELECT e.id INTO v_education_id
                    FROM m_education e
                    JOIN t_education_mapping em ON e.id = em.education_id
                    WHERE em.user_id = p_user_id
                    AND e.education_level = (v_education->>'educationLevel')::text
                    AND e.organisation = (v_education->>'organisation')::text
                    AND e.start_date = (v_education->>'startDate')::timestamp;

                    IF v_education_id IS NULL THEN
                        RAISE EXCEPTION 'Education record not found for user with educationLevel %, organisation %, startDate %', 
                            (v_education->>'educationLevel')::text, 
                            (v_education->>'organisation')::text, 
                            (v_education->>'startDate')::timestamp;
                    END IF;

                    -- Update the existing education record
                    UPDATE m_education
                    SET
                        education_level = (v_education->>'educationLevel')::text,
                        organisation = (v_education->>'organisation')::text,
                        start_date = (v_education->>'startDate')::timestamp,
                        end_date = CASE
                            WHEN v_education->>'endDate' IS NULL THEN NULL
                            ELSE (v_education->>'endDate')::timestamp
                        END
                    WHERE id = v_education_id;
                END IF;
            END LOOP;
        END IF;

        -- Update or insert Experience entries if provided
        IF v_experience_array IS NOT NULL AND jsonb_array_length(v_experience_array) > 0 THEN
            FOR v_index IN 0..(jsonb_array_length(v_experience_array) - 1)
            LOOP
                v_experience := v_experience_array->v_index;
                v_experience_id := (v_experience->>'experienceId')::bigint;

                IF v_experience_id IS NOT NULL THEN
                    -- Update existing experience record
                    IF NOT EXISTS (
                        SELECT 1
                        FROM t_user_experience
                        WHERE id = v_experience_id AND user_id = p_user_id
                    ) THEN
                        RAISE EXCEPTION 'Experience record % not found for user', v_experience_id;
                    END IF;

                    UPDATE t_user_experience
                    SET
                        company_id = (v_experience->>'companyId')::integer,
                        designation_id = (v_experience->>'designationId')::integer,
                        start_date = (v_experience->>'startDate')::timestamp,
                        end_date = CASE
                            WHEN v_experience->>'endDate' IS NULL THEN NULL
                            ELSE (v_experience->>'endDate')::timestamp
                        END,
                        currently_pursuing = (v_experience->>'currentlyPursuing')::boolean
                    WHERE id = v_experience_id;
                ELSE
                    -- Insert new experience record
                    INSERT INTO t_user_experience (
                        user_id,
                        company_id,
                        designation_id,
                        start_date,
                        end_date,
                        currently_pursuing
                    )
                    VALUES (
                        p_user_id,
                        (v_experience->>'companyId')::integer,
                        (v_experience->>'designationId')::integer,
                        (v_experience->>'startDate')::timestamp,
                        CASE
                            WHEN v_experience->>'endDate' IS NULL THEN NULL
                            ELSE (v_experience->>'endDate')::timestamp
                        END,
                        (v_experience->>'currentlyPursuing')::boolean
                    )
                    RETURNING id INTO v_experience_id;
                END IF;
            END LOOP;
        END IF;

        -- Return success message
        RETURN QUERY
        SELECT 'Profile updated successfully'::text, 1::integer;

    EXCEPTION WHEN OTHERS THEN
        -- Roll back the transaction and return error message
        RETURN QUERY
        SELECT ('Error updating profile: ' || SQLERRM)::text, 0::integer;
    END;
END;
$$;


ALTER FUNCTION public.fn_update_user_profile(p_user_id bigint, p_profile_data jsonb) OWNER TO postgres;

--
-- Name: fn_user_get_editable_fields(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_get_editable_fields(p_user_id bigint) RETURNS TABLE(resulttype integer, resultmessage text, user_id bigint, first_name character varying, last_name character varying, user_name character varying, phone_number character varying, email character varying, bio text, location character varying, profile_pic character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_resulttype INTEGER := 1; -- Default success
    v_resultmessage TEXT := '';
    v_userid BIGINT := 0;
    v_record_exists BOOLEAN;
BEGIN
    -- Check if user exists and is not deleted
    SELECT EXISTS (
        SELECT 1 
        FROM m_user 
        WHERE id = p_user_id 
        AND is_deleted = FALSE
    ) INTO v_record_exists;

    IF NOT v_record_exists THEN
        v_resulttype := 0;
        v_resultmessage := 'User not found or has been deleted';
        RETURN QUERY SELECT 
            v_resulttype, 
            v_resultmessage, 
            p_user_id::bigint,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::text,
            NULL::character varying,
            NULL::character varying;
    ELSE
        v_resultmessage := 'User data retrieved successfully';
        v_userid := p_user_id;
        
        RETURN QUERY
        SELECT 
            v_resulttype,
            v_resultmessage,
            mu.id,
            mu.first_name,
            mu.last_name,
            mu.user_name,
            mu.phone_number,
            mu.email,
            mu.bio,
            mu.location,
            mu.profile_pic
        FROM m_user mu
        WHERE mu.id = p_user_id 
        AND mu.is_deleted = FALSE;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_user_get_editable_fields(p_user_id bigint) OWNER TO postgres;

--
-- Name: fn_user_search(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_search(p_search_text character varying) RETURNS TABLE(user_id bigint, user_name character varying, email character varying, phone_number character varying, location character varying, bio character varying, user_type_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    record_count INT;
BEGIN
    -- Check if any matching records exist
    SELECT COUNT(*) INTO record_count
    FROM m_user mu
    INNER JOIN m_usertype user_type ON user_type.id = mu.user_type
    WHERE 
        (mu.user_name ILIKE '%' || p_search_text || '%'
        OR mu.email ILIKE '%' || p_search_text || '%'
        OR mu.bio ILIKE '%' || p_search_text || '%'
        OR mu.location ILIKE '%' || p_search_text || '%'
        OR mu.first_name ILIKE '%' || p_search_text || '%'
        OR mu.last_name ILIKE '%' || p_search_text || '%')
        AND mu.is_active = TRUE  -- Only active users
        AND mu.is_deleted = FALSE; -- Exclude deleted users

    -- If no records found, display a message
    IF record_count = 0 THEN
        RAISE NOTICE 'No records found for search text: %', p_search_text;
        RETURN;
    END IF;

    -- If records found, return the query results
    RETURN QUERY
    SELECT 
        mu.id AS user_id,
        mu.user_name,
        mu.email,
        mu.phone_number,
        mu.location,
        mu.bio::VARCHAR,  -- Explicitly cast bio to VARCHAR
        user_type.user_type AS user_type_name
    FROM m_user mu
    INNER JOIN m_usertype user_type ON user_type.id = mu.user_type
    WHERE 
        (mu.user_name ILIKE '%' || p_search_text || '%'
        OR mu.email ILIKE '%' || p_search_text || '%'
        OR mu.bio ILIKE '%' || p_search_text || '%'
        OR mu.location ILIKE '%' || p_search_text || '%'
        OR mu.first_name ILIKE '%' || p_search_text || '%'
        OR mu.last_name ILIKE '%' || p_search_text || '%')
        AND mu.is_active = TRUE  -- Only active users
        AND mu.is_deleted = FALSE; -- Exclude deleted users
END;
$$;


ALTER FUNCTION public.fn_user_search(p_search_text character varying) OWNER TO postgres;

--
-- Name: fn_user_select_id(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_select_id(p_user_id bigint) RETURNS TABLE(user_id bigint, first_name character varying, last_name character varying, user_name character varying, phone_number character varying, email character varying, is_active boolean, is_deleted boolean, gender_id smallint, gender_name character varying, user_type_id smallint, user_type_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mu.id AS user_id,
        mu.first_name,
        COALESCE(mu.last_name, '') AS last_name,  -- NULL check only for last_name
        mu.user_name,
        mu.phone_number,
        mu.email,
        mu.is_active,
        mu.is_deleted AS is_deleted,
        mu.gender::SMALLINT AS gender_id,  -- Use mu.gender instead of mg.id
        mg.gender AS gender_name,
        mu.user_type::SMALLINT AS user_type_id,  -- Use mu.user_type instead of mt.id
        mt.user_type AS user_type_name
    FROM m_user mu
    INNER JOIN m_usertype mt ON mt.id = mu.user_type
    INNER JOIN m_gender mg ON mg.id = mu.gender
    WHERE mu.id = p_user_id;
END;
$$;


ALTER FUNCTION public.fn_user_select_id(p_user_id bigint) OWNER TO postgres;

--
-- Name: fn_validate_account(character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validate_account(ip_email_or_phone character varying, ip_password character varying, ip_is_sso_login boolean DEFAULT false) RETURNS TABLE(user_id bigint, resultmessage character varying, resulttype integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user RECORD;
    v_max_attempts CONSTANT INTEGER := 3;
BEGIN
    -- Check m_user
    SELECT id, password, is_active, is_deleted, is_sso_user, COALESCE(login_attempt_count, 0) AS login_attempt_count
    INTO v_user
    FROM public.m_user
    WHERE (LOWER(TRIM(email)) = LOWER(TRIM(ip_email_or_phone))
           OR (LOWER(TRIM(phone_number)) = LOWER(TRIM(ip_email_or_phone)) AND phone_number IS NOT NULL))
          AND is_deleted = false
    LIMIT 1;

    -- If no user is found
    IF v_user IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, 'User not found'::VARCHAR, 0;
        RETURN;
    END IF;

    -- Check if account is inactive
    IF NOT v_user.is_active THEN
        RETURN QUERY SELECT NULL::BIGINT, 'Account is inactive'::VARCHAR, 2;
        RETURN;
    END IF;

    -- Handle SSO login
    IF ip_is_sso_login THEN
        IF v_user.is_sso_user THEN
            RETURN QUERY SELECT v_user.id::BIGINT, 'Successfully logged in via SSO'::VARCHAR, 1;
            RETURN;
        ELSE
            RETURN QUERY SELECT v_user.id::BIGINT, 'Non-SSO account. Please provide password'::VARCHAR, 3;
            RETURN;
        END IF;
    END IF;

    -- Check if password is set for non-SSO login
    IF v_user.password IS NULL OR TRIM(v_user.password) = '' THEN
        RETURN QUERY SELECT NULL::BIGINT, 'No password set for this account. Use SSO login'::VARCHAR, 4;
        RETURN;
    END IF;

    -- Check login attempt limit
    IF v_user.login_attempt_count >= v_max_attempts THEN
        RETURN QUERY SELECT NULL::BIGINT, 'Account locked due to too many failed attempts'::VARCHAR, 0;
        RETURN;
    END IF;

    -- Validate password
    IF v_user.password = ip_password THEN
        -- Reset login attempt count on successful login
        UPDATE public.m_user
        SET login_attempt_count = 0,
            updated_on = CURRENT_TIMESTAMP
        WHERE id = v_user.id;

        RETURN QUERY SELECT v_user.id::BIGINT, 'Successfully logged in'::VARCHAR, 1;
    ELSE
        -- Increment login attempt count on failure
        UPDATE public.m_user
        SET login_attempt_count = v_user.login_attempt_count + 1,
            updated_on = CURRENT_TIMESTAMP
        WHERE id = v_user.id
            AND v_user.login_attempt_count < v_max_attempts;

        RETURN QUERY SELECT NULL::BIGINT,
                           CASE 
                               WHEN v_user.login_attempt_count + 1 >= v_max_attempts 
                               THEN 'Account locked due to too many failed attempts'::VARCHAR 
                               ELSE 'Invalid email/phone or password'::VARCHAR 
                           END,
                           0;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::BIGINT, ('An error occurred: ' || SQLERRM)::VARCHAR, 99;
END;
$$;


ALTER FUNCTION public.fn_validate_account(ip_email_or_phone character varying, ip_password character varying, ip_is_sso_login boolean) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: m_account_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_account_type (
    id smallint NOT NULL,
    account_type character varying NOT NULL
);


ALTER TABLE public.m_account_type OWNER TO postgres;

--
-- Name: m_account_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_account_type_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_account_type_id_seq OWNER TO postgres;

--
-- Name: m_account_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_account_type_id_seq OWNED BY public.m_account_type.id;


--
-- Name: m_activity_sub_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_activity_sub_type (
    id integer NOT NULL,
    parent_id bigint NOT NULL,
    child_name character varying(50) NOT NULL,
    CONSTRAINT check_child_name CHECK (((child_name)::text = ANY ((ARRAY['Login'::character varying, 'Logout'::character varying, 'Created'::character varying, 'Updated'::character varying, 'Deleted'::character varying])::text[])))
);


ALTER TABLE public.m_activity_sub_type OWNER TO postgres;

--
-- Name: m_activity_sub_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_activity_sub_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_activity_sub_type_id_seq OWNER TO postgres;

--
-- Name: m_activity_sub_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_activity_sub_type_id_seq OWNED BY public.m_activity_sub_type.id;


--
-- Name: m_activity_sub_type_parent_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_activity_sub_type_parent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_activity_sub_type_parent_id_seq OWNER TO postgres;

--
-- Name: m_activity_sub_type_parent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_activity_sub_type_parent_id_seq OWNED BY public.m_activity_sub_type.parent_id;


--
-- Name: m_activity_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_activity_type (
    id smallint NOT NULL,
    activity_type character varying NOT NULL,
    CONSTRAINT check_activity_type CHECK (((activity_type)::text = ANY ((ARRAY['authorization'::character varying, 'Post'::character varying, 'Job'::character varying, 'Course'::character varying, 'Business'::character varying])::text[])))
);


ALTER TABLE public.m_activity_type OWNER TO postgres;

--
-- Name: m_activity_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_activity_type_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_activity_type_id_seq OWNER TO postgres;

--
-- Name: m_activity_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_activity_type_id_seq OWNED BY public.m_activity_type.id;


--
-- Name: m_companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_companies (
    id integer NOT NULL,
    company_name character varying NOT NULL,
    location character varying,
    location_type character varying,
    description character varying,
    CONSTRAINT m_companies_location_type_check CHECK (((location_type)::text = ANY ((ARRAY['onsite'::character varying, 'hybrid'::character varying, 'remote'::character varying])::text[])))
);


ALTER TABLE public.m_companies OWNER TO postgres;

--
-- Name: m_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_companies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_companies_id_seq OWNER TO postgres;

--
-- Name: m_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_companies_id_seq OWNED BY public.m_companies.id;


--
-- Name: m_course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_course (
    id integer NOT NULL,
    course_name character varying(200) NOT NULL,
    course_type integer NOT NULL,
    level integer NOT NULL,
    subscription_type integer NOT NULL,
    status integer NOT NULL,
    course_thumbnail text,
    course_banner text,
    certification_available boolean DEFAULT false,
    description text,
    cost numeric,
    preview_video_url text,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.m_course OWNER TO postgres;

--
-- Name: m_course_course_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_course_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_course_type_seq OWNER TO postgres;

--
-- Name: m_course_course_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_course_type_seq OWNED BY public.m_course.course_type;


--
-- Name: m_course_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_id_seq OWNER TO postgres;

--
-- Name: m_course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_id_seq OWNED BY public.m_course.id;


--
-- Name: m_course_level; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_course_level (
    id bigint NOT NULL,
    level character varying(50) NOT NULL,
    CONSTRAINT check_level CHECK (((level)::text = ANY ((ARRAY['Beginner'::character varying, 'Intermediate'::character varying, 'Advanced'::character varying])::text[])))
);


ALTER TABLE public.m_course_level OWNER TO postgres;

--
-- Name: m_course_level_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_level_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_level_id_seq OWNER TO postgres;

--
-- Name: m_course_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_level_id_seq OWNED BY public.m_course_level.id;


--
-- Name: m_course_level_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_level_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_level_seq OWNER TO postgres;

--
-- Name: m_course_level_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_level_seq OWNED BY public.m_course.level;


--
-- Name: m_course_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_course_mapping (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    course_id integer NOT NULL,
    valid_from date NOT NULL,
    valid_to date
);


ALTER TABLE public.m_course_mapping OWNER TO postgres;

--
-- Name: m_course_mapping_course_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_mapping_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_mapping_course_id_seq OWNER TO postgres;

--
-- Name: m_course_mapping_course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_mapping_course_id_seq OWNED BY public.m_course_mapping.course_id;


--
-- Name: m_course_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_mapping_id_seq OWNER TO postgres;

--
-- Name: m_course_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_mapping_id_seq OWNED BY public.m_course_mapping.id;


--
-- Name: m_course_mapping_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_mapping_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_mapping_user_id_seq OWNER TO postgres;

--
-- Name: m_course_mapping_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_mapping_user_id_seq OWNED BY public.m_course_mapping.user_id;


--
-- Name: m_course_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_course_status (
    id integer NOT NULL,
    status_name character varying(50) NOT NULL,
    CONSTRAINT check_status_name CHECK (((status_name)::text = ANY ((ARRAY['Pending'::character varying, 'Approved'::character varying, 'Rejected'::character varying])::text[])))
);


ALTER TABLE public.m_course_status OWNER TO postgres;

--
-- Name: m_course_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_status_id_seq OWNER TO postgres;

--
-- Name: m_course_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_status_id_seq OWNED BY public.m_course_status.id;


--
-- Name: m_course_status_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_status_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_status_seq OWNER TO postgres;

--
-- Name: m_course_status_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_status_seq OWNED BY public.m_course.status;


--
-- Name: m_course_subscription_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_subscription_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_subscription_type_seq OWNER TO postgres;

--
-- Name: m_course_subscription_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_subscription_type_seq OWNED BY public.m_course.subscription_type;


--
-- Name: m_course_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_course_type (
    id bigint NOT NULL,
    course_type character varying(50) NOT NULL,
    CONSTRAINT check_course_type CHECK (((course_type)::text = ANY ((ARRAY['Video'::character varying, 'PDF'::character varying])::text[])))
);


ALTER TABLE public.m_course_type OWNER TO postgres;

--
-- Name: m_course_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_course_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_course_type_id_seq OWNER TO postgres;

--
-- Name: m_course_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_course_type_id_seq OWNED BY public.m_course_type.id;


--
-- Name: m_currency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_currency (
    id integer NOT NULL,
    currency_code character varying(3) NOT NULL,
    currency_symbol character varying(10)
);


ALTER TABLE public.m_currency OWNER TO postgres;

--
-- Name: m_currency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_currency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_currency_id_seq OWNER TO postgres;

--
-- Name: m_currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_currency_id_seq OWNED BY public.m_currency.id;


--
-- Name: m_designations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_designations (
    id integer NOT NULL,
    designation character varying NOT NULL,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.m_designations OWNER TO postgres;

--
-- Name: m_designations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_designations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_designations_id_seq OWNER TO postgres;

--
-- Name: m_designations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_designations_id_seq OWNED BY public.m_designations.id;


--
-- Name: m_education; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_education (
    id smallint NOT NULL,
    education_level character varying(20),
    organisation text,
    start_date date,
    end_date date
);


ALTER TABLE public.m_education OWNER TO postgres;

--
-- Name: m_education_education_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_education_education_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_education_education_id_seq OWNER TO postgres;

--
-- Name: m_education_education_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_education_education_id_seq OWNED BY public.m_education.id;


--
-- Name: m_education_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_education_id_seq
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_education_id_seq OWNER TO postgres;

--
-- Name: m_education_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_education_id_seq OWNED BY public.m_education.id;


--
-- Name: m_gender; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_gender (
    id smallint NOT NULL,
    gender character varying NOT NULL,
    CONSTRAINT m_gender_gender_check CHECK (((gender)::text = ANY ((ARRAY['Male'::character varying, 'Female'::character varying, 'Others'::character varying])::text[])))
);


ALTER TABLE public.m_gender OWNER TO postgres;

--
-- Name: m_gender_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_gender_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_gender_id_seq OWNER TO postgres;

--
-- Name: m_gender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_gender_id_seq OWNED BY public.m_gender.id;


--
-- Name: m_industry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_industry (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true
);


ALTER TABLE public.m_industry OWNER TO postgres;

--
-- Name: m_industry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_industry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_industry_id_seq OWNER TO postgres;

--
-- Name: m_industry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_industry_id_seq OWNED BY public.m_industry.id;


--
-- Name: m_institution; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_institution (
    institution_id integer NOT NULL,
    institution_name character varying NOT NULL,
    institution_type character varying(20),
    CONSTRAINT m_institution_institution_type_check CHECK (((institution_type)::text = ANY ((ARRAY['university'::character varying, 'college'::character varying, 'school'::character varying])::text[])))
);


ALTER TABLE public.m_institution OWNER TO postgres;

--
-- Name: m_institution_institution_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_institution_institution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_institution_institution_id_seq OWNER TO postgres;

--
-- Name: m_institution_institution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_institution_institution_id_seq OWNED BY public.m_institution.institution_id;


--
-- Name: m_item_view; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_item_view (
    id integer NOT NULL,
    item_id integer NOT NULL,
    item_type character varying(50) NOT NULL,
    viewed_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_item_type CHECK (((item_type)::text = ANY ((ARRAY['Course'::character varying, 'Post'::character varying, 'Job'::character varying])::text[])))
);


ALTER TABLE public.m_item_view OWNER TO postgres;

--
-- Name: m_item_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_item_view_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_item_view_id_seq OWNER TO postgres;

--
-- Name: m_item_view_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_item_view_id_seq OWNED BY public.m_item_view.id;


--
-- Name: m_item_view_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_item_view_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_item_view_item_id_seq OWNER TO postgres;

--
-- Name: m_item_view_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_item_view_item_id_seq OWNED BY public.m_item_view.item_id;


--
-- Name: m_job; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_job (
    id integer NOT NULL,
    organisation_id integer NOT NULL,
    designation_id integer NOT NULL,
    description text NOT NULL,
    requirement text,
    location character varying(200),
    job_type integer NOT NULL,
    job_mode integer NOT NULL,
    hashtags text,
    pay_currency integer NOT NULL,
    pay_start_range numeric,
    pay_end_range numeric,
    opening_date date,
    closing_date date,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.m_job OWNER TO postgres;

--
-- Name: m_job_application; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_job_application (
    id integer NOT NULL,
    job_id integer NOT NULL,
    resume_path text,
    status integer NOT NULL,
    applied_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.m_job_application OWNER TO postgres;

--
-- Name: m_job_application_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_application_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_application_id_seq OWNER TO postgres;

--
-- Name: m_job_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_application_id_seq OWNED BY public.m_job_application.id;


--
-- Name: m_job_application_job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_application_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_application_job_id_seq OWNER TO postgres;

--
-- Name: m_job_application_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_application_job_id_seq OWNED BY public.m_job_application.job_id;


--
-- Name: m_job_application_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_job_application_status (
    id integer NOT NULL,
    status character varying(50) NOT NULL,
    CONSTRAINT check_status CHECK (((status)::text = ANY ((ARRAY['Pending'::character varying, 'Accepted'::character varying])::text[])))
);


ALTER TABLE public.m_job_application_status OWNER TO postgres;

--
-- Name: m_job_application_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_application_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_application_status_id_seq OWNER TO postgres;

--
-- Name: m_job_application_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_application_status_id_seq OWNED BY public.m_job_application_status.id;


--
-- Name: m_job_application_status_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_application_status_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_application_status_seq OWNER TO postgres;

--
-- Name: m_job_application_status_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_application_status_seq OWNED BY public.m_job_application.status;


--
-- Name: m_job_company_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_company_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_company_id_seq OWNER TO postgres;

--
-- Name: m_job_company_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_company_id_seq OWNED BY public.m_job.organisation_id;


--
-- Name: m_job_designation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_designation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_designation_id_seq OWNER TO postgres;

--
-- Name: m_job_designation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_designation_id_seq OWNED BY public.m_job.designation_id;


--
-- Name: m_job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_id_seq OWNER TO postgres;

--
-- Name: m_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_id_seq OWNED BY public.m_job.id;


--
-- Name: m_job_job_mode_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_job_mode_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_job_mode_seq OWNER TO postgres;

--
-- Name: m_job_job_mode_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_job_mode_seq OWNED BY public.m_job.job_mode;


--
-- Name: m_job_job_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_job_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_job_type_seq OWNER TO postgres;

--
-- Name: m_job_job_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_job_type_seq OWNED BY public.m_job.job_type;


--
-- Name: m_job_mode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_job_mode (
    id integer NOT NULL,
    job_mode character varying(50) NOT NULL,
    CONSTRAINT check_job_mode CHECK (((job_mode)::text = ANY ((ARRAY['Remote'::character varying, 'Onsite'::character varying, 'Hybrid'::character varying])::text[])))
);


ALTER TABLE public.m_job_mode OWNER TO postgres;

--
-- Name: m_job_mode_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_mode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_mode_id_seq OWNER TO postgres;

--
-- Name: m_job_mode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_mode_id_seq OWNED BY public.m_job_mode.id;


--
-- Name: m_job_pay_currency_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_pay_currency_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_pay_currency_seq OWNER TO postgres;

--
-- Name: m_job_pay_currency_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_pay_currency_seq OWNED BY public.m_job.pay_currency;


--
-- Name: m_job_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_job_type (
    id integer NOT NULL,
    job_type character varying(50) NOT NULL,
    CONSTRAINT check_job_type CHECK (((job_type)::text = ANY ((ARRAY['Full-time'::character varying, 'Part-time'::character varying, 'Internship'::character varying])::text[])))
);


ALTER TABLE public.m_job_type OWNER TO postgres;

--
-- Name: m_job_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_job_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_job_type_id_seq OWNER TO postgres;

--
-- Name: m_job_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_job_type_id_seq OWNED BY public.m_job_type.id;


--
-- Name: m_organisation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_organisation (
    id integer NOT NULL,
    industry_id integer NOT NULL,
    pay_currency integer NOT NULL,
    email character varying(255) NOT NULL,
    contact_number character varying(20),
    organisation_name character varying(200) NOT NULL,
    address character varying(500),
    description text,
    banner_url character varying(255),
    logo_url character varying(255),
    social_link character varying(255),
    website_link character varying(255),
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_on timestamp with time zone,
    is_sso_login boolean,
    password character varying(255),
    is_active boolean DEFAULT true,
    login_attempt_count integer DEFAULT 0
);


ALTER TABLE public.m_organisation OWNER TO postgres;

--
-- Name: m_organisation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_organisation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_organisation_id_seq OWNER TO postgres;

--
-- Name: m_organisation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_organisation_id_seq OWNED BY public.m_organisation.id;


--
-- Name: m_organisation_industry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_organisation_industry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_organisation_industry_id_seq OWNER TO postgres;

--
-- Name: m_organisation_industry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_organisation_industry_id_seq OWNED BY public.m_organisation.industry_id;


--
-- Name: m_organisation_pay_currency_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_organisation_pay_currency_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_organisation_pay_currency_seq OWNER TO postgres;

--
-- Name: m_organisation_pay_currency_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_organisation_pay_currency_seq OWNED BY public.m_organisation.pay_currency;


--
-- Name: m_post; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_post (
    id integer NOT NULL,
    content text NOT NULL,
    media_url text,
    hashtags text,
    post_visibility character varying(50) NOT NULL,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_post_visibility CHECK (((post_visibility)::text = ANY ((ARRAY['Anyone'::character varying, 'Connections Only'::character varying, 'Group'::character varying])::text[])))
);


ALTER TABLE public.m_post OWNER TO postgres;

--
-- Name: m_post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_post_id_seq OWNER TO postgres;

--
-- Name: m_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_post_id_seq OWNED BY public.m_post.id;


--
-- Name: m_report_activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_report_activity (
    id integer NOT NULL,
    reporter_id bigint NOT NULL,
    reported_activity character varying(50) NOT NULL,
    reported_activity_id integer NOT NULL,
    reason text NOT NULL,
    reported_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_reported_activity CHECK (((reported_activity)::text = ANY ((ARRAY['Post'::character varying, 'Job'::character varying, 'Course'::character varying])::text[])))
);


ALTER TABLE public.m_report_activity OWNER TO postgres;

--
-- Name: m_report_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_report_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_report_activity_id_seq OWNER TO postgres;

--
-- Name: m_report_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_report_activity_id_seq OWNED BY public.m_report_activity.id;


--
-- Name: m_report_activity_reported_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_report_activity_reported_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_report_activity_reported_activity_id_seq OWNER TO postgres;

--
-- Name: m_report_activity_reported_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_report_activity_reported_activity_id_seq OWNED BY public.m_report_activity.reported_activity_id;


--
-- Name: m_report_activity_reporter_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_report_activity_reporter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_report_activity_reporter_id_seq OWNER TO postgres;

--
-- Name: m_report_activity_reporter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_report_activity_reporter_id_seq OWNED BY public.m_report_activity.reporter_id;


--
-- Name: m_report_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_report_profile (
    id integer NOT NULL,
    reporter_id bigint NOT NULL,
    reported_id bigint NOT NULL,
    reason text NOT NULL,
    reported_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.m_report_profile OWNER TO postgres;

--
-- Name: m_report_profile_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_report_profile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_report_profile_id_seq OWNER TO postgres;

--
-- Name: m_report_profile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_report_profile_id_seq OWNED BY public.m_report_profile.id;


--
-- Name: m_report_profile_reported_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_report_profile_reported_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_report_profile_reported_id_seq OWNER TO postgres;

--
-- Name: m_report_profile_reported_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_report_profile_reported_id_seq OWNED BY public.m_report_profile.reported_id;


--
-- Name: m_report_profile_reporter_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_report_profile_reporter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_report_profile_reporter_id_seq OWNER TO postgres;

--
-- Name: m_report_profile_reporter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_report_profile_reporter_id_seq OWNED BY public.m_report_profile.reporter_id;


--
-- Name: m_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_skills (
    id integer NOT NULL,
    skill_name character varying NOT NULL,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.m_skills OWNER TO postgres;

--
-- Name: m_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_skills_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_skills_id_seq OWNER TO postgres;

--
-- Name: m_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_skills_id_seq OWNED BY public.m_skills.id;


--
-- Name: m_subscription_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_subscription_type (
    id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    CONSTRAINT check_type_name CHECK (((type_name)::text = ANY ((ARRAY['Free'::character varying, 'Paid'::character varying])::text[])))
);


ALTER TABLE public.m_subscription_type OWNER TO postgres;

--
-- Name: m_subscription_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_subscription_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_subscription_type_id_seq OWNER TO postgres;

--
-- Name: m_subscription_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_subscription_type_id_seq OWNED BY public.m_subscription_type.id;


--
-- Name: m_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.m_user (
    id bigint NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    phone_number character varying,
    email character varying NOT NULL,
    password character varying,
    account_type bigint DEFAULT 1,
    gender smallint,
    profile_pic character varying,
    bio character varying,
    location character varying,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by bigint,
    updated_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint,
    login_attempt_count smallint DEFAULT 0,
    is_active boolean DEFAULT true,
    is_reset boolean DEFAULT false,
    is_deleted boolean,
    is_sso_user boolean DEFAULT false,
    social_link character varying,
    CONSTRAINT m_user_login_attempt_count_check CHECK (((login_attempt_count >= 0) AND (login_attempt_count <= 3)))
);


ALTER TABLE public.m_user OWNER TO postgres;

--
-- Name: t_user_experience; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_user_experience (
    id smallint NOT NULL,
    user_id smallint,
    company_id smallint,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    designation_id smallint,
    currently_pursuing boolean
);


ALTER TABLE public.t_user_experience OWNER TO postgres;

--
-- Name: m_user_experience_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_user_experience_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_user_experience_id_seq OWNER TO postgres;

--
-- Name: m_user_experience_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_user_experience_id_seq OWNED BY public.t_user_experience.id;


--
-- Name: m_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.m_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.m_user_id_seq OWNER TO postgres;

--
-- Name: m_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.m_user_id_seq OWNED BY public.m_user.id;


--
-- Name: t_course_likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_course_likes (
    id integer NOT NULL,
    course_id integer NOT NULL,
    liked_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_course_likes OWNER TO postgres;

--
-- Name: t_course_likes_course_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_course_likes_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_course_likes_course_id_seq OWNER TO postgres;

--
-- Name: t_course_likes_course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_course_likes_course_id_seq OWNED BY public.t_course_likes.course_id;


--
-- Name: t_course_likes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_course_likes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_course_likes_id_seq OWNER TO postgres;

--
-- Name: t_course_likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_course_likes_id_seq OWNED BY public.t_course_likes.id;


--
-- Name: t_course_share; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_course_share (
    id integer NOT NULL,
    course_id integer NOT NULL,
    shared_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_id bigint
);


ALTER TABLE public.t_course_share OWNER TO postgres;

--
-- Name: t_course_share_course_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_course_share_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_course_share_course_id_seq OWNER TO postgres;

--
-- Name: t_course_share_course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_course_share_course_id_seq OWNED BY public.t_course_share.course_id;


--
-- Name: t_course_share_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_course_share_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_course_share_id_seq OWNER TO postgres;

--
-- Name: t_course_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_course_share_id_seq OWNED BY public.t_course_share.id;


--
-- Name: t_education_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_education_mapping (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    education_id integer NOT NULL
);


ALTER TABLE public.t_education_mapping OWNER TO postgres;

--
-- Name: t_education_mapping_education_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_education_mapping_education_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_education_mapping_education_id_seq OWNER TO postgres;

--
-- Name: t_education_mapping_education_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_education_mapping_education_id_seq OWNED BY public.t_education_mapping.education_id;


--
-- Name: t_education_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_education_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_education_mapping_id_seq OWNER TO postgres;

--
-- Name: t_education_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_education_mapping_id_seq OWNED BY public.t_education_mapping.id;


--
-- Name: t_education_mapping_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_education_mapping_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_education_mapping_user_id_seq OWNER TO postgres;

--
-- Name: t_education_mapping_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_education_mapping_user_id_seq OWNED BY public.t_education_mapping.user_id;


--
-- Name: t_job_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_job_mapping (
    id integer NOT NULL,
    job_id integer NOT NULL,
    posted_by integer NOT NULL,
    account_type character varying(50) NOT NULL,
    CONSTRAINT check_account_type CHECK (((account_type)::text = ANY ((ARRAY['Company'::character varying, 'Student'::character varying, 'Admin'::character varying])::text[])))
);


ALTER TABLE public.t_job_mapping OWNER TO postgres;

--
-- Name: t_job_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_job_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_job_mapping_id_seq OWNER TO postgres;

--
-- Name: t_job_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_job_mapping_id_seq OWNED BY public.t_job_mapping.id;


--
-- Name: t_job_mapping_job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_job_mapping_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_job_mapping_job_id_seq OWNER TO postgres;

--
-- Name: t_job_mapping_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_job_mapping_job_id_seq OWNED BY public.t_job_mapping.job_id;


--
-- Name: t_job_share; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_job_share (
    id integer NOT NULL,
    job_id integer NOT NULL,
    shared_by bigint NOT NULL,
    shared_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_job_share OWNER TO postgres;

--
-- Name: t_job_share_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_job_share_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_job_share_id_seq OWNER TO postgres;

--
-- Name: t_job_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_job_share_id_seq OWNED BY public.t_job_share.id;


--
-- Name: t_job_share_job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_job_share_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_job_share_job_id_seq OWNER TO postgres;

--
-- Name: t_job_share_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_job_share_job_id_seq OWNED BY public.t_job_share.job_id;


--
-- Name: t_job_share_shared_by_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_job_share_shared_by_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_job_share_shared_by_seq OWNER TO postgres;

--
-- Name: t_job_share_shared_by_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_job_share_shared_by_seq OWNED BY public.t_job_share.shared_by;


--
-- Name: t_mention_tracking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_mention_tracking (
    id integer NOT NULL,
    item_id integer NOT NULL,
    item_type character varying(50) NOT NULL,
    m_id integer NOT NULL,
    account_type character varying(50) NOT NULL,
    m_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_account_type CHECK (((account_type)::text = ANY ((ARRAY['User'::character varying, 'Organization'::character varying])::text[]))),
    CONSTRAINT check_item_type CHECK (((item_type)::text = ANY ((ARRAY['Post'::character varying, 'Job'::character varying, 'Course'::character varying])::text[])))
);


ALTER TABLE public.t_mention_tracking OWNER TO postgres;

--
-- Name: t_mention_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_mention_tracking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_mention_tracking_id_seq OWNER TO postgres;

--
-- Name: t_mention_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_mention_tracking_id_seq OWNED BY public.t_mention_tracking.id;


--
-- Name: t_post_comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_post_comment (
    id integer NOT NULL,
    post_id integer NOT NULL,
    comment character varying(1000) NOT NULL,
    parent_comment_id integer DEFAULT 0,
    is_deleted boolean DEFAULT false,
    commented_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_post_comment OWNER TO postgres;

--
-- Name: t_post_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_comment_id_seq OWNER TO postgres;

--
-- Name: t_post_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_comment_id_seq OWNED BY public.t_post_comment.id;


--
-- Name: t_post_comment_post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_comment_post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_comment_post_id_seq OWNER TO postgres;

--
-- Name: t_post_comment_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_comment_post_id_seq OWNED BY public.t_post_comment.post_id;


--
-- Name: t_post_likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_post_likes (
    id integer NOT NULL,
    post_id integer NOT NULL,
    liked_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_post_likes OWNER TO postgres;

--
-- Name: t_post_likes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_likes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_likes_id_seq OWNER TO postgres;

--
-- Name: t_post_likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_likes_id_seq OWNED BY public.t_post_likes.id;


--
-- Name: t_post_likes_post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_likes_post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_likes_post_id_seq OWNER TO postgres;

--
-- Name: t_post_likes_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_likes_post_id_seq OWNED BY public.t_post_likes.post_id;


--
-- Name: t_post_share; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_post_share (
    id integer NOT NULL,
    post_id integer NOT NULL,
    shared_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_post_share OWNER TO postgres;

--
-- Name: t_post_share_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_share_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_share_id_seq OWNER TO postgres;

--
-- Name: t_post_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_share_id_seq OWNED BY public.t_post_share.id;


--
-- Name: t_post_share_post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_share_post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_share_post_id_seq OWNER TO postgres;

--
-- Name: t_post_share_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_share_post_id_seq OWNED BY public.t_post_share.post_id;


--
-- Name: t_post_tracking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_post_tracking (
    id integer NOT NULL,
    post_id integer NOT NULL,
    posted_by integer NOT NULL,
    account_type character varying(50) NOT NULL,
    CONSTRAINT check_account_type CHECK (((account_type)::text = ANY ((ARRAY['User'::character varying, 'Organization'::character varying])::text[])))
);


ALTER TABLE public.t_post_tracking OWNER TO postgres;

--
-- Name: t_post_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_tracking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_tracking_id_seq OWNER TO postgres;

--
-- Name: t_post_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_tracking_id_seq OWNED BY public.t_post_tracking.id;


--
-- Name: t_post_tracking_post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_post_tracking_post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_post_tracking_post_id_seq OWNER TO postgres;

--
-- Name: t_post_tracking_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_post_tracking_post_id_seq OWNED BY public.t_post_tracking.post_id;


--
-- Name: t_report_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_report_action (
    id integer NOT NULL,
    report_type character varying(50) NOT NULL,
    report_id integer NOT NULL,
    action_taken text NOT NULL,
    action_by bigint NOT NULL,
    action_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_report_type CHECK (((report_type)::text = ANY ((ARRAY['Profile'::character varying, 'Activity'::character varying])::text[])))
);


ALTER TABLE public.t_report_action OWNER TO postgres;

--
-- Name: t_report_action_action_by_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_report_action_action_by_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_report_action_action_by_seq OWNER TO postgres;

--
-- Name: t_report_action_action_by_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_report_action_action_by_seq OWNED BY public.t_report_action.action_by;


--
-- Name: t_report_action_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_report_action_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_report_action_id_seq OWNER TO postgres;

--
-- Name: t_report_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_report_action_id_seq OWNED BY public.t_report_action.id;


--
-- Name: t_report_action_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_report_action_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_report_action_report_id_seq OWNER TO postgres;

--
-- Name: t_report_action_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_report_action_report_id_seq OWNED BY public.t_report_action.report_id;


--
-- Name: t_tag_tracking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_tag_tracking (
    id integer NOT NULL,
    item_id integer NOT NULL,
    item_type character varying(50) NOT NULL,
    tag_name character varying(100) NOT NULL,
    CONSTRAINT check_item_type CHECK (((item_type)::text = ANY ((ARRAY['Post'::character varying, 'Job'::character varying, 'Course'::character varying])::text[])))
);


ALTER TABLE public.t_tag_tracking OWNER TO postgres;

--
-- Name: t_tag_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_tag_tracking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_tag_tracking_id_seq OWNER TO postgres;

--
-- Name: t_tag_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_tag_tracking_id_seq OWNED BY public.t_tag_tracking.id;


--
-- Name: t_user_activity_track; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_user_activity_track (
    id integer NOT NULL,
    user_id integer,
    activity_type_id smallint NOT NULL,
    activity_datetime timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    device_info character varying
);


ALTER TABLE public.t_user_activity_track OWNER TO postgres;

--
-- Name: t_user_activity_track_activity_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_user_activity_track_activity_type_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_user_activity_track_activity_type_id_seq OWNER TO postgres;

--
-- Name: t_user_activity_track_activity_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_user_activity_track_activity_type_id_seq OWNED BY public.t_user_activity_track.activity_type_id;


--
-- Name: t_user_activity_track_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_user_activity_track_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_user_activity_track_id_seq OWNER TO postgres;

--
-- Name: t_user_activity_track_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_user_activity_track_id_seq OWNED BY public.t_user_activity_track.id;


--
-- Name: t_user_skill_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_user_skill_mapping (
    id integer NOT NULL,
    user_id integer,
    skill_id integer
);


ALTER TABLE public.t_user_skill_mapping OWNER TO postgres;

--
-- Name: t_user_skill_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.t_user_skill_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.t_user_skill_mapping_id_seq OWNER TO postgres;

--
-- Name: t_user_skill_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.t_user_skill_mapping_id_seq OWNED BY public.t_user_skill_mapping.id;


--
-- Name: m_account_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_account_type ALTER COLUMN id SET DEFAULT nextval('public.m_account_type_id_seq'::regclass);


--
-- Name: m_activity_sub_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_sub_type ALTER COLUMN id SET DEFAULT nextval('public.m_activity_sub_type_id_seq'::regclass);


--
-- Name: m_activity_sub_type parent_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_sub_type ALTER COLUMN parent_id SET DEFAULT nextval('public.m_activity_sub_type_parent_id_seq'::regclass);


--
-- Name: m_activity_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_type ALTER COLUMN id SET DEFAULT nextval('public.m_activity_type_id_seq'::regclass);


--
-- Name: m_companies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_companies ALTER COLUMN id SET DEFAULT nextval('public.m_companies_id_seq'::regclass);


--
-- Name: m_course id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course ALTER COLUMN id SET DEFAULT nextval('public.m_course_id_seq'::regclass);


--
-- Name: m_course course_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course ALTER COLUMN course_type SET DEFAULT nextval('public.m_course_course_type_seq'::regclass);


--
-- Name: m_course level; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course ALTER COLUMN level SET DEFAULT nextval('public.m_course_level_seq'::regclass);


--
-- Name: m_course subscription_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course ALTER COLUMN subscription_type SET DEFAULT nextval('public.m_course_subscription_type_seq'::regclass);


--
-- Name: m_course status; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course ALTER COLUMN status SET DEFAULT nextval('public.m_course_status_seq'::regclass);


--
-- Name: m_course_level id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_level ALTER COLUMN id SET DEFAULT nextval('public.m_course_level_id_seq'::regclass);


--
-- Name: m_course_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_mapping ALTER COLUMN id SET DEFAULT nextval('public.m_course_mapping_id_seq'::regclass);


--
-- Name: m_course_mapping user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_mapping ALTER COLUMN user_id SET DEFAULT nextval('public.m_course_mapping_user_id_seq'::regclass);


--
-- Name: m_course_mapping course_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_mapping ALTER COLUMN course_id SET DEFAULT nextval('public.m_course_mapping_course_id_seq'::regclass);


--
-- Name: m_course_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_status ALTER COLUMN id SET DEFAULT nextval('public.m_course_status_id_seq'::regclass);


--
-- Name: m_course_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_type ALTER COLUMN id SET DEFAULT nextval('public.m_course_type_id_seq'::regclass);


--
-- Name: m_currency id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_currency ALTER COLUMN id SET DEFAULT nextval('public.m_currency_id_seq'::regclass);


--
-- Name: m_designations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_designations ALTER COLUMN id SET DEFAULT nextval('public.m_designations_id_seq'::regclass);


--
-- Name: m_education id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_education ALTER COLUMN id SET DEFAULT nextval('public.m_education_id_seq'::regclass);


--
-- Name: m_gender id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_gender ALTER COLUMN id SET DEFAULT nextval('public.m_gender_id_seq'::regclass);


--
-- Name: m_industry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_industry ALTER COLUMN id SET DEFAULT nextval('public.m_industry_id_seq'::regclass);


--
-- Name: m_institution institution_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_institution ALTER COLUMN institution_id SET DEFAULT nextval('public.m_institution_institution_id_seq'::regclass);


--
-- Name: m_item_view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_item_view ALTER COLUMN id SET DEFAULT nextval('public.m_item_view_id_seq'::regclass);


--
-- Name: m_item_view item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_item_view ALTER COLUMN item_id SET DEFAULT nextval('public.m_item_view_item_id_seq'::regclass);


--
-- Name: m_job id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job ALTER COLUMN id SET DEFAULT nextval('public.m_job_id_seq'::regclass);


--
-- Name: m_job organisation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job ALTER COLUMN organisation_id SET DEFAULT nextval('public.m_job_company_id_seq'::regclass);


--
-- Name: m_job designation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job ALTER COLUMN designation_id SET DEFAULT nextval('public.m_job_designation_id_seq'::regclass);


--
-- Name: m_job job_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job ALTER COLUMN job_type SET DEFAULT nextval('public.m_job_job_type_seq'::regclass);


--
-- Name: m_job job_mode; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job ALTER COLUMN job_mode SET DEFAULT nextval('public.m_job_job_mode_seq'::regclass);


--
-- Name: m_job pay_currency; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job ALTER COLUMN pay_currency SET DEFAULT nextval('public.m_job_pay_currency_seq'::regclass);


--
-- Name: m_job_application id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application ALTER COLUMN id SET DEFAULT nextval('public.m_job_application_id_seq'::regclass);


--
-- Name: m_job_application job_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application ALTER COLUMN job_id SET DEFAULT nextval('public.m_job_application_job_id_seq'::regclass);


--
-- Name: m_job_application status; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application ALTER COLUMN status SET DEFAULT nextval('public.m_job_application_status_seq'::regclass);


--
-- Name: m_job_application_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application_status ALTER COLUMN id SET DEFAULT nextval('public.m_job_application_status_id_seq'::regclass);


--
-- Name: m_job_mode id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_mode ALTER COLUMN id SET DEFAULT nextval('public.m_job_mode_id_seq'::regclass);


--
-- Name: m_job_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_type ALTER COLUMN id SET DEFAULT nextval('public.m_job_type_id_seq'::regclass);


--
-- Name: m_organisation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation ALTER COLUMN id SET DEFAULT nextval('public.m_organisation_id_seq'::regclass);


--
-- Name: m_organisation industry_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation ALTER COLUMN industry_id SET DEFAULT nextval('public.m_organisation_industry_id_seq'::regclass);


--
-- Name: m_organisation pay_currency; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation ALTER COLUMN pay_currency SET DEFAULT nextval('public.m_organisation_pay_currency_seq'::regclass);


--
-- Name: m_post id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_post ALTER COLUMN id SET DEFAULT nextval('public.m_post_id_seq'::regclass);


--
-- Name: m_report_activity id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_activity ALTER COLUMN id SET DEFAULT nextval('public.m_report_activity_id_seq'::regclass);


--
-- Name: m_report_activity reporter_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_activity ALTER COLUMN reporter_id SET DEFAULT nextval('public.m_report_activity_reporter_id_seq'::regclass);


--
-- Name: m_report_activity reported_activity_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_activity ALTER COLUMN reported_activity_id SET DEFAULT nextval('public.m_report_activity_reported_activity_id_seq'::regclass);


--
-- Name: m_report_profile id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_profile ALTER COLUMN id SET DEFAULT nextval('public.m_report_profile_id_seq'::regclass);


--
-- Name: m_report_profile reporter_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_profile ALTER COLUMN reporter_id SET DEFAULT nextval('public.m_report_profile_reporter_id_seq'::regclass);


--
-- Name: m_report_profile reported_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_profile ALTER COLUMN reported_id SET DEFAULT nextval('public.m_report_profile_reported_id_seq'::regclass);


--
-- Name: m_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_skills ALTER COLUMN id SET DEFAULT nextval('public.m_skills_id_seq'::regclass);


--
-- Name: m_subscription_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_subscription_type ALTER COLUMN id SET DEFAULT nextval('public.m_subscription_type_id_seq'::regclass);


--
-- Name: m_user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user ALTER COLUMN id SET DEFAULT nextval('public.m_user_id_seq'::regclass);


--
-- Name: t_course_likes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_likes ALTER COLUMN id SET DEFAULT nextval('public.t_course_likes_id_seq'::regclass);


--
-- Name: t_course_likes course_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_likes ALTER COLUMN course_id SET DEFAULT nextval('public.t_course_likes_course_id_seq'::regclass);


--
-- Name: t_course_share id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_share ALTER COLUMN id SET DEFAULT nextval('public.t_course_share_id_seq'::regclass);


--
-- Name: t_course_share course_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_share ALTER COLUMN course_id SET DEFAULT nextval('public.t_course_share_course_id_seq'::regclass);


--
-- Name: t_education_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_education_mapping ALTER COLUMN id SET DEFAULT nextval('public.t_education_mapping_id_seq'::regclass);


--
-- Name: t_education_mapping user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_education_mapping ALTER COLUMN user_id SET DEFAULT nextval('public.t_education_mapping_user_id_seq'::regclass);


--
-- Name: t_education_mapping education_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_education_mapping ALTER COLUMN education_id SET DEFAULT nextval('public.t_education_mapping_education_id_seq'::regclass);


--
-- Name: t_job_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_mapping ALTER COLUMN id SET DEFAULT nextval('public.t_job_mapping_id_seq'::regclass);


--
-- Name: t_job_mapping job_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_mapping ALTER COLUMN job_id SET DEFAULT nextval('public.t_job_mapping_job_id_seq'::regclass);


--
-- Name: t_job_share id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_share ALTER COLUMN id SET DEFAULT nextval('public.t_job_share_id_seq'::regclass);


--
-- Name: t_job_share job_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_share ALTER COLUMN job_id SET DEFAULT nextval('public.t_job_share_job_id_seq'::regclass);


--
-- Name: t_job_share shared_by; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_share ALTER COLUMN shared_by SET DEFAULT nextval('public.t_job_share_shared_by_seq'::regclass);


--
-- Name: t_mention_tracking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_mention_tracking ALTER COLUMN id SET DEFAULT nextval('public.t_mention_tracking_id_seq'::regclass);


--
-- Name: t_post_comment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_comment ALTER COLUMN id SET DEFAULT nextval('public.t_post_comment_id_seq'::regclass);


--
-- Name: t_post_comment post_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_comment ALTER COLUMN post_id SET DEFAULT nextval('public.t_post_comment_post_id_seq'::regclass);


--
-- Name: t_post_likes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_likes ALTER COLUMN id SET DEFAULT nextval('public.t_post_likes_id_seq'::regclass);


--
-- Name: t_post_likes post_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_likes ALTER COLUMN post_id SET DEFAULT nextval('public.t_post_likes_post_id_seq'::regclass);


--
-- Name: t_post_share id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_share ALTER COLUMN id SET DEFAULT nextval('public.t_post_share_id_seq'::regclass);


--
-- Name: t_post_share post_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_share ALTER COLUMN post_id SET DEFAULT nextval('public.t_post_share_post_id_seq'::regclass);


--
-- Name: t_post_tracking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_tracking ALTER COLUMN id SET DEFAULT nextval('public.t_post_tracking_id_seq'::regclass);


--
-- Name: t_post_tracking post_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_tracking ALTER COLUMN post_id SET DEFAULT nextval('public.t_post_tracking_post_id_seq'::regclass);


--
-- Name: t_report_action id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_report_action ALTER COLUMN id SET DEFAULT nextval('public.t_report_action_id_seq'::regclass);


--
-- Name: t_report_action report_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_report_action ALTER COLUMN report_id SET DEFAULT nextval('public.t_report_action_report_id_seq'::regclass);


--
-- Name: t_report_action action_by; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_report_action ALTER COLUMN action_by SET DEFAULT nextval('public.t_report_action_action_by_seq'::regclass);


--
-- Name: t_tag_tracking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_tag_tracking ALTER COLUMN id SET DEFAULT nextval('public.t_tag_tracking_id_seq'::regclass);


--
-- Name: t_user_activity_track id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_activity_track ALTER COLUMN id SET DEFAULT nextval('public.t_user_activity_track_id_seq'::regclass);


--
-- Name: t_user_activity_track activity_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_activity_track ALTER COLUMN activity_type_id SET DEFAULT nextval('public.t_user_activity_track_activity_type_id_seq'::regclass);


--
-- Name: t_user_experience id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_experience ALTER COLUMN id SET DEFAULT nextval('public.m_user_experience_id_seq'::regclass);


--
-- Name: t_user_skill_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_skill_mapping ALTER COLUMN id SET DEFAULT nextval('public.t_user_skill_mapping_id_seq'::regclass);


--
-- Data for Name: m_account_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_account_type (id, account_type) FROM stdin;
1	User
2	Organization
\.


--
-- Data for Name: m_activity_sub_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_activity_sub_type (id, parent_id, child_name) FROM stdin;
\.


--
-- Data for Name: m_activity_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_activity_type (id, activity_type) FROM stdin;
\.


--
-- Data for Name: m_companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_companies (id, company_name, location, location_type, description) FROM stdin;
1	Infosys	Chennai	onsite	Infosys is the best
\.


--
-- Data for Name: m_course; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_course (id, course_name, course_type, level, subscription_type, status, course_thumbnail, course_banner, certification_available, description, cost, preview_video_url, created_on) FROM stdin;
1	Python	2	1	2	3	python.jpg	banner.jpg	t	python is a good course	5000	video.url	2025-05-07 16:25:43.163224+05:30
\.


--
-- Data for Name: m_course_level; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_course_level (id, level) FROM stdin;
1	Beginner
2	Intermediate
3	Advanced
\.


--
-- Data for Name: m_course_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_course_mapping (id, user_id, course_id, valid_from, valid_to) FROM stdin;
1	1	1	2025-05-01	2025-08-01
\.


--
-- Data for Name: m_course_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_course_status (id, status_name) FROM stdin;
2	Pending
3	Approved
4	Rejected
\.


--
-- Data for Name: m_course_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_course_type (id, course_type) FROM stdin;
1	Video
2	PDF
\.


--
-- Data for Name: m_currency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_currency (id, currency_code, currency_symbol) FROM stdin;
1	INR	₹
2	USD	$
\.


--
-- Data for Name: m_designations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_designations (id, designation, created_on) FROM stdin;
1	Developer	2024-12-01 15:30:00+05:30
2	Developer	2024-12-01 15:30:00+05:30
3	Software	2025-05-07 12:11:01.418944+05:30
4	HR	2025-05-07 12:11:52.671229+05:30
\.


--
-- Data for Name: m_education; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_education (id, education_level, organisation, start_date, end_date) FROM stdin;
5	SSLC	NITTE	2014-12-12	2015-12-12
6	PUC	NITTE	2015-12-12	2017-12-12
7	BSC	NITTE	2017-12-12	2020-12-12
8	MCA	NITTE	2020-12-12	\N
9	PhD in Data Science	Harvard University	2024-01-01	\N
10	PhD in Data Science	Harvard University	2024-01-01	\N
\.


--
-- Data for Name: m_gender; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_gender (id, gender) FROM stdin;
1	Male
2	Female
3	Others
\.


--
-- Data for Name: m_industry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_industry (id, name, is_active) FROM stdin;
1	MRPL	t
2	ORCL	t
3	Education	t
\.


--
-- Data for Name: m_institution; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_institution (institution_id, institution_name, institution_type) FROM stdin;
\.


--
-- Data for Name: m_item_view; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_item_view (id, item_id, item_type, viewed_on) FROM stdin;
\.


--
-- Data for Name: m_job; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_job (id, organisation_id, designation_id, description, requirement, location, job_type, job_mode, hashtags, pay_currency, pay_start_range, pay_end_range, opening_date, closing_date, created_on) FROM stdin;
1	15	1	Software Engineer role focusing on backend development.	B.Tech in Computer Science, 2+ years of experience in backend development.	Bangalore, India	1	2	#SoftwareEngineer #Backend #TechJobs	1	800000	1200000	2025-01-01	2025-06-30	2024-12-01 10:00:00+05:30
2	16	2	Data Analyst position with a focus on machine learning.	M.Sc in Data Science, proficiency in Python and ML frameworks.	Remote	1	1	#DataAnalyst #MachineLearning #RemoteJobs	2	60000	80000	2025-02-01	2025-07-31	2025-01-15 14:30:00+05:30
3	20	2	Good job	Good knowledge in C,C++,Java	Mangalore	3	2	#developer #java	2	40000	60000	2025-05-07	2025-06-06	2025-05-07 13:41:21.762193+05:30
\.


--
-- Data for Name: m_job_application; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_job_application (id, job_id, resume_path, status, applied_on) FROM stdin;
\.


--
-- Data for Name: m_job_application_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_job_application_status (id, status) FROM stdin;
\.


--
-- Data for Name: m_job_mode; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_job_mode (id, job_mode) FROM stdin;
1	Remote
2	Onsite
3	Hybrid
\.


--
-- Data for Name: m_job_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_job_type (id, job_type) FROM stdin;
1	Full-time
2	Part-time
3	Internship
\.


--
-- Data for Name: m_organisation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_organisation (id, industry_id, pay_currency, email, contact_number, organisation_name, address, description, banner_url, logo_url, social_link, website_link, created_on, updated_on, is_sso_login, password, is_active, login_attempt_count) FROM stdin;
16	2	2	info@financeinc.com	\N	Finance Inc	\N	\N	\N	\N	\N	\N	2025-04-16 19:20:34.397955+05:30	\N	f	\N	t	0
19	1	1	org@example.com	+1234567890	MyOrg	123 Main St	Hello	banner.jpg	logo.jpg	https://social.com/org	https://org.com	2025-04-24 16:44:19.997762+05:30	2025-04-24 16:52:53.128656+05:30	f	\N	t	0
20	1	2	varsha@gmail.com	7411369875	Google	Bangalore	Google is the best company	banner.jpg	logo.jpg	varsha.com	varsha1.com	2025-05-07 12:51:44.140199+05:30	2025-05-07 12:51:44.140199+05:30	f	secure123	t	0
15	1	1	contact@techcorp.com	\N	Tech Corp	\N	\N	\N	\N	\N	\N	2025-04-16 19:20:34.397955+05:30	\N	t	\N	t	0
\.


--
-- Data for Name: m_post; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_post (id, content, media_url, hashtags, post_visibility, created_on) FROM stdin;
1	This is the post	post.jpg	#post	Anyone	2025-05-07 18:27:16.019767+05:30
\.


--
-- Data for Name: m_report_activity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_report_activity (id, reporter_id, reported_activity, reported_activity_id, reason, reported_on) FROM stdin;
\.


--
-- Data for Name: m_report_profile; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_report_profile (id, reporter_id, reported_id, reason, reported_on) FROM stdin;
\.


--
-- Data for Name: m_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_skills (id, skill_name, created_on) FROM stdin;
\.


--
-- Data for Name: m_subscription_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_subscription_type (id, type_name) FROM stdin;
1	Free
2	Paid
\.


--
-- Data for Name: m_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.m_user (id, first_name, last_name, phone_number, email, password, account_type, gender, profile_pic, bio, location, created_on, created_by, updated_on, updated_by, login_attempt_count, is_active, is_reset, is_deleted, is_sso_user, social_link) FROM stdin;
21	John	Doe	9876543291	john1.doe@example.com	$2a$06$W8Z7WfNnb4O4NfL20.v2Te6LBK7CsF7BCdlFFN1p0u3oj/Fj6dT62	\N	1	\N	\N	\N	2025-04-17 10:39:47.013138+05:30	\N	2025-04-17 10:39:47.013138+05:30	\N	0	t	f	f	f	\N
27	Soundarya	rai	9876543210	soundu.doe@example.com	$2a$06$wb9TKyQ63noryBvNmOJsvuBrcTtg4sQIWO8aHY/uwZVr3qUwHawua	1	1	profile.jpg	Just a regular girl	New York	2025-04-17 15:18:16.280644+05:30	1	2025-04-17 15:18:16.280644+05:30	1	0	t	f	f	f	https://twitter.com/johndoe
28	Sharanya	shetty	98765432678	sharuhetty10@gmail.com	$2a$06$4kCM0NZeSEV1PWPYpCotROFFtWmOuGpDk65Zgs/zu6KA799K9E/Ee	1	1	profile.jpg	Just a regular girl	Udupi	2025-04-17 15:23:29.927662+05:30	1	2025-04-17 15:23:29.927662+05:30	1	0	t	f	f	f	https://twitter.com/johndoe
26	John	Doe	+911234567890	john7.doe@example.com	25656ca3d45cdf9b408418aee743134553cdb0f631933c5a596c2df0073e355c	1	1	\N	\N	\N	2025-04-17 11:46:48.279379+05:30	1	2025-05-13 13:08:06.932378+05:30	1	2	t	f	f	f	\N
32	Vishwa	Shetty	+91786543215	shetty@example.com	$2a$06$x6mFPSmaCrhtosBDwJL3K.MDJ2XLtQ4U0s3iS5xzVgVMwZxF6.kOa	1	2	string	string	string	2025-04-17 16:49:51.807424+05:30	1	2025-04-17 16:49:51.807424+05:30	1	0	t	f	t	t	string
9	Vishwa	Roopa	9876543211	vishwa@example.com	Vishwa@123	1	1	profile.jpg	Software Engineer	New	2025-04-16 17:00:48.954993+05:30	1	2025-04-29 11:06:53.277295+05:30	1	0	t	f	f	f	https://linkedin.com/vishwaroopa
2	Admin	User	1234567890	admin@example.com	240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9	1	1	\N	System user	Unknown	2025-04-02 13:44:56.314153+05:30	1	2025-04-20 17:06:59.089617+05:30	1	2	t	f	f	f	\N
7	Vishwa	Shetty	9986387911	vishwashetty10@gmail.com	6e4eeed5bfe10a81f97071d4af45ec07b89df72a9ea604a38da8377a87dd3025	1	1		New user	Udupi	2025-04-02 15:45:47.772879+05:30	1	2025-04-20 17:08:25.742018+05:30	7	1	t	t	f	f	\N
29	Rakshitha	D	+919087654321	rakshitha@example.com	$2a$06$4JwNReVoiClmAtmCEhzB3eYlLqad8GAIzhiI5X8Je/0PKbIhBywRe	1	1	profile.jpg	A software developer	Mangalore	2025-04-17 16:01:34.107867+05:30	1	2025-04-20 17:11:23.046915+05:30	1	2	t	f	f	f	https://twitter.com/johndoe
33	Varsha	Borker	7586741231	varsha@example.com	Varsha@123	1	2	varsha.jpg	This is varsha	Palli	2025-05-13 13:43:04.279531+05:30	1	2025-05-13 13:43:04.279531+05:30	1	0	t	f	f	f	varsha.com
35	Amit	Sharma	+919876543210	amit.sharma@example.com	password123	1	1	amit.jpg	this is amit	dubai	2025-05-13 15:53:20.218532+05:30	1	2025-05-13 15:53:20.218532+05:30	1	0	t	f	f	f	amitsharma.com
15	John	Doe	+919876543200	john.doe@example.com	25656ca3d45cdf9b408418aee743134553cdb0f631933c5a596c2df0073e355c	\N	2	\N	\N	\N	2025-04-17 03:03:16.93034+05:30	\N	2025-04-17 03:03:16.93034+05:30	\N	0	t	f	f	f	\N
1	Radha	Shetty	7411321751	radha.shetty@gmail.com	faa8ddccdb5c557e4d9984e497d580694a6c87df8811f1d7a7c3c435180e2762	1	1	profile_updated.jpg	Updated bio	Mumbai	2025-04-02 13:42:02.705146+05:30	1	2025-04-17 15:27:27.534378+05:30	1	0	t	f	f	f	https://twitter.com/radhashetty
43	qvish	bsbs	+91464646464664	vishwashetty855@gmail.com	c206fbbc248aaa2209e3f4d6470293cff4e0bec8b6e3b10ed84cb461532d6c2b	1	2	\N	\N	\N	2025-05-27 00:59:28.292047+05:30	1	2025-05-27 00:59:28.292047+05:30	1	0	t	f	f	f	\N
17	Vishwaa	Roopa	98765432110	vishwa1@example.com	25656ca3d45cdf9b408418aee743134553cdb0f631933c5a596c2df0073e355c	\N	2	\N	\N	\N	2025-04-17 03:07:52.361699+05:30	\N	2025-04-30 10:17:48.208133+05:30	\N	0	t	f	f	f	\N
38	Vasu	Shetty	+917411589632	vasu@gmail.com	1731d3023960ee0d285dcbeb5cad9da145e8bf0a25cd5ba3f0a377fadb06713b	1	2	\N	\N	\N	2025-05-15 11:03:43.196202+05:30	1	2025-05-15 11:28:22.166375+05:30	38	0	t	t	f	f	\N
8	Sajith	Salian	1234567892	sajith.salian@example.com	25656ca3d45cdf9b408418aee743134553cdb0f631933c5a596c2df0073e355c	1	1	profile.jpg	Software developer	Bangalore	2025-04-10 15:03:32.266716+05:30	1	2025-05-13 17:37:11.509725+05:30	1	1	t	t	f	f	\N
5	Vishwa	Shetty	9986387901	vishwashetty11@gmail.com	25656ca3d45cdf9b408418aee743134553cdb0f631933c5a596c2df0073e355c	1	1		New user	Udupi	2025-04-02 15:18:34.358607+05:30	1	2025-05-13 13:01:40.885026+05:30	1	0	t	t	f	f	\N
19	Vishwaa	Roopa	88765432110	vishwa11@example.com	$2a$06$783BX9qyPp9d.dJdnA7NO.gkNtgY1OA7opnUQXjHmnjQuAzsugpce	\N	2	\N	\N	\N	2025-04-17 03:14:24.103749+05:30	\N	2025-05-13 12:11:41.812336+05:30	\N	2	t	f	f	f	\N
37	Prajna	JK	+91957461236	prajna@example.com	9b89a9e4dc63cbe659db78e9daa4ef433f84e55578fd58969f58155e6a425c0b	1	2	prajna.jpg	This is the prajna	Udupi	2025-05-13 18:13:27.16161+05:30	1	2025-05-21 11:18:18.079857+05:30	37	1	t	t	f	f	prajna.com
42	v	g	+918533992584	v@gmail.com	c206fbbc248aaa2209e3f4d6470293cff4e0bec8b6e3b10ed84cb461532d6c2b	1	2	\N	\N	\N	2025-05-23 15:06:47.00357+05:30	1	2025-05-23 15:06:47.00357+05:30	1	0	t	f	f	f	\N
41	Vishwa	Roopa	+917411321768	vishwaroopa@example.com	992888c5afaa49c755fa22ed5e74547cc565bb2df38ac5afb523704ea14f3a39	1	2	https://example.com/profile/vishwa.jpg	Tech enthusiast and Android developer passionate about solving real-world problems.	Udupi, Karnataka	2025-05-23 07:59:28.501147+05:30	1	2025-06-09 08:00:59.459579+05:30	1	0	t	f	f	f	https://linkedin.com/in/vishwa-roopa-a62238235
44	pusha	latha	+918762696278	pushpa@gmail.com	c206fbbc248aaa2209e3f4d6470293cff4e0bec8b6e3b10ed84cb461532d6c2b	1	2	\N	\N	\N	2025-06-03 23:10:02.399523+05:30	1	2025-06-03 23:10:02.399523+05:30	1	0	t	f	f	f	\N
45	Meghana	Naik	+918741235698	Meghana@gmail.con	c206fbbc248aaa2209e3f4d6470293cff4e0bec8b6e3b10ed84cb461532d6c2b	1	2	\N	\N	\N	2025-06-09 08:04:30.233797+05:30	1	2025-06-09 08:04:30.233797+05:30	1	0	t	f	f	f	\N
46	Anagha	rai	+918523697586	anagha87@gmail.con	c206fbbc248aaa2209e3f4d6470293cff4e0bec8b6e3b10ed84cb461532d6c2b	1	2	\N	\N	\N	2025-06-09 08:12:31.157872+05:30	1	2025-06-09 08:12:31.157872+05:30	1	0	t	f	f	f	\N
40	Krithi	Rao	+919876543243	krithi.rao@example.com	5d0b903a	1	2	https://example.com/images/krithi.jpg	Creative designer and digital artist.	Bangalore, India	2025-05-21 11:42:51.569062+05:30	1	2025-06-09 11:01:50.891172+05:30	40	1	t	t	f	f	https://instagram.com/krithidesigns
50	gagan	Doe	9876543011	gagan.doe@example.com	9dde4ab2	\N	1	\N	\N	\N	2025-06-09 11:26:47.848914+05:30	\N	2025-06-09 11:26:47.848914+05:30	\N	0	t	f	f	f	\N
51	Akhila	jasmine	9871616161	akhila@example.com	2b855c25	\N	2	\N	\N	\N	2025-06-09 12:33:39.760575+05:30	\N	2025-06-09 12:33:39.760575+05:30	\N	0	t	f	f	f	\N
52	Gagan	Naik	+9185369852715	gagan@gmail.com	207293e7	\N	1	\N	\N	\N	2025-06-09 14:09:29.933603+05:30	\N	2025-06-09 14:09:29.933603+05:30	\N	0	t	f	f	f	\N
53	Rama	Seetha	+9185316494545	ram@gmail.com	1aaf5e10	\N	1	\N	\N	\N	2025-06-09 14:16:53.576592+05:30	\N	2025-06-09 14:18:40.550984+05:30	\N	1	t	f	f	f	\N
54	Supriyaa	Shetty	+91854346616764	supriya@gmail.com	174ab243	\N	2	\N	\N	\N	2025-06-09 14:21:14.075905+05:30	\N	2025-06-09 14:22:21.062406+05:30	\N	1	t	f	f	f	\N
56	Radha	Shetty	9876546810	radha@example.com	c5767651	\N	2	\N	\N	\N	2025-06-09 16:09:53.242406+05:30	\N	2025-06-09 16:09:53.242406+05:30	\N	0	t	f	f	f	\N
57	gagan	naik	9876543016	gagan@example.com	b9555184	\N	1	\N	\N	\N	2025-06-09 16:18:03.340678+05:30	\N	2025-06-09 16:18:03.340678+05:30	\N	0	t	f	f	f	\N
58	gagan	naik	9876543013	gagannaik@example.com	2a7809f9	1	1	\N	\N	\N	2025-06-09 16:58:56.900324+05:30	\N	2025-06-09 16:58:56.900324+05:30	\N	0	t	f	f	f	\N
55	Sudha	Shetty	+918523666696	sudha@gmail.com	3fe5ee96	\N	2	\N	\N	\N	2025-06-09 15:29:38.104203+05:30	\N	2025-06-09 16:06:09.954797+05:30	\N	1	t	f	f	f	\N
\.


--
-- Data for Name: t_course_likes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_course_likes (id, course_id, liked_on) FROM stdin;
\.


--
-- Data for Name: t_course_share; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_course_share (id, course_id, shared_on, user_id) FROM stdin;
\.


--
-- Data for Name: t_education_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_education_mapping (id, user_id, education_id) FROM stdin;
2	1	5
3	1	6
4	1	7
5	1	8
6	1	9
7	1	10
\.


--
-- Data for Name: t_job_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_job_mapping (id, job_id, posted_by, account_type) FROM stdin;
5	1	1	Company
\.


--
-- Data for Name: t_job_share; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_job_share (id, job_id, shared_by, shared_on) FROM stdin;
\.


--
-- Data for Name: t_mention_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_mention_tracking (id, item_id, item_type, m_id, account_type, m_date) FROM stdin;
\.


--
-- Data for Name: t_post_comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_post_comment (id, post_id, comment, parent_comment_id, is_deleted, commented_on) FROM stdin;
\.


--
-- Data for Name: t_post_likes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_post_likes (id, post_id, liked_on) FROM stdin;
\.


--
-- Data for Name: t_post_share; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_post_share (id, post_id, shared_on) FROM stdin;
\.


--
-- Data for Name: t_post_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_post_tracking (id, post_id, posted_by, account_type) FROM stdin;
1	1	1	User
\.


--
-- Data for Name: t_report_action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_report_action (id, report_type, report_id, action_taken, action_by, action_on) FROM stdin;
\.


--
-- Data for Name: t_tag_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_tag_tracking (id, item_id, item_type, tag_name) FROM stdin;
\.


--
-- Data for Name: t_user_activity_track; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_user_activity_track (id, user_id, activity_type_id, activity_datetime, device_info) FROM stdin;
\.


--
-- Data for Name: t_user_experience; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_user_experience (id, user_id, company_id, start_date, end_date, designation_id, currently_pursuing) FROM stdin;
4	1	1	2014-12-12 00:00:00+05:30	2015-12-12 00:00:00+05:30	1	t
\.


--
-- Data for Name: t_user_skill_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t_user_skill_mapping (id, user_id, skill_id) FROM stdin;
\.


--
-- Name: m_account_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_account_type_id_seq', 2, true);


--
-- Name: m_activity_sub_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_activity_sub_type_id_seq', 1, false);


--
-- Name: m_activity_sub_type_parent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_activity_sub_type_parent_id_seq', 1, false);


--
-- Name: m_activity_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_activity_type_id_seq', 1, false);


--
-- Name: m_companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_companies_id_seq', 1, true);


--
-- Name: m_course_course_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_course_type_seq', 1, false);


--
-- Name: m_course_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_id_seq', 1, true);


--
-- Name: m_course_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_level_id_seq', 3, true);


--
-- Name: m_course_level_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_level_seq', 1, false);


--
-- Name: m_course_mapping_course_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_mapping_course_id_seq', 1, false);


--
-- Name: m_course_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_mapping_id_seq', 1, true);


--
-- Name: m_course_mapping_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_mapping_user_id_seq', 1, false);


--
-- Name: m_course_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_status_id_seq', 4, true);


--
-- Name: m_course_status_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_status_seq', 1, false);


--
-- Name: m_course_subscription_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_subscription_type_seq', 1, false);


--
-- Name: m_course_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_course_type_id_seq', 2, true);


--
-- Name: m_currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_currency_id_seq', 1, false);


--
-- Name: m_designations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_designations_id_seq', 4, true);


--
-- Name: m_education_education_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_education_education_id_seq', 1, false);


--
-- Name: m_education_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_education_id_seq', 10, true);


--
-- Name: m_gender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_gender_id_seq', 4, true);


--
-- Name: m_industry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_industry_id_seq', 3, true);


--
-- Name: m_institution_institution_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_institution_institution_id_seq', 1, false);


--
-- Name: m_item_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_item_view_id_seq', 1, false);


--
-- Name: m_item_view_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_item_view_item_id_seq', 1, false);


--
-- Name: m_job_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_application_id_seq', 1, false);


--
-- Name: m_job_application_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_application_job_id_seq', 1, false);


--
-- Name: m_job_application_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_application_status_id_seq', 1, false);


--
-- Name: m_job_application_status_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_application_status_seq', 1, false);


--
-- Name: m_job_company_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_company_id_seq', 1, false);


--
-- Name: m_job_designation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_designation_id_seq', 1, false);


--
-- Name: m_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_id_seq', 3, true);


--
-- Name: m_job_job_mode_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_job_mode_seq', 1, false);


--
-- Name: m_job_job_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_job_type_seq', 1, false);


--
-- Name: m_job_mode_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_mode_id_seq', 3, true);


--
-- Name: m_job_pay_currency_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_pay_currency_seq', 1, false);


--
-- Name: m_job_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_job_type_id_seq', 3, true);


--
-- Name: m_organisation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_organisation_id_seq', 20, true);


--
-- Name: m_organisation_industry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_organisation_industry_id_seq', 1, false);


--
-- Name: m_organisation_pay_currency_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_organisation_pay_currency_seq', 1, false);


--
-- Name: m_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_post_id_seq', 1, true);


--
-- Name: m_report_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_report_activity_id_seq', 1, false);


--
-- Name: m_report_activity_reported_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_report_activity_reported_activity_id_seq', 1, false);


--
-- Name: m_report_activity_reporter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_report_activity_reporter_id_seq', 1, false);


--
-- Name: m_report_profile_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_report_profile_id_seq', 1, false);


--
-- Name: m_report_profile_reported_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_report_profile_reported_id_seq', 1, false);


--
-- Name: m_report_profile_reporter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_report_profile_reporter_id_seq', 1, false);


--
-- Name: m_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_skills_id_seq', 1, false);


--
-- Name: m_subscription_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_subscription_type_id_seq', 2, true);


--
-- Name: m_user_experience_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_user_experience_id_seq', 4, true);


--
-- Name: m_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.m_user_id_seq', 63, true);


--
-- Name: t_course_likes_course_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_course_likes_course_id_seq', 1, false);


--
-- Name: t_course_likes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_course_likes_id_seq', 1, false);


--
-- Name: t_course_share_course_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_course_share_course_id_seq', 1, false);


--
-- Name: t_course_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_course_share_id_seq', 1, false);


--
-- Name: t_education_mapping_education_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_education_mapping_education_id_seq', 1, false);


--
-- Name: t_education_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_education_mapping_id_seq', 7, true);


--
-- Name: t_education_mapping_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_education_mapping_user_id_seq', 1, false);


--
-- Name: t_job_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_job_mapping_id_seq', 5, true);


--
-- Name: t_job_mapping_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_job_mapping_job_id_seq', 1, false);


--
-- Name: t_job_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_job_share_id_seq', 1, false);


--
-- Name: t_job_share_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_job_share_job_id_seq', 1, false);


--
-- Name: t_job_share_shared_by_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_job_share_shared_by_seq', 1, false);


--
-- Name: t_mention_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_mention_tracking_id_seq', 1, false);


--
-- Name: t_post_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_comment_id_seq', 1, false);


--
-- Name: t_post_comment_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_comment_post_id_seq', 1, false);


--
-- Name: t_post_likes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_likes_id_seq', 1, false);


--
-- Name: t_post_likes_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_likes_post_id_seq', 1, false);


--
-- Name: t_post_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_share_id_seq', 1, false);


--
-- Name: t_post_share_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_share_post_id_seq', 1, false);


--
-- Name: t_post_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_tracking_id_seq', 1, true);


--
-- Name: t_post_tracking_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_post_tracking_post_id_seq', 1, false);


--
-- Name: t_report_action_action_by_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_report_action_action_by_seq', 1, false);


--
-- Name: t_report_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_report_action_id_seq', 1, false);


--
-- Name: t_report_action_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_report_action_report_id_seq', 1, false);


--
-- Name: t_tag_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_tag_tracking_id_seq', 1, false);


--
-- Name: t_user_activity_track_activity_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_user_activity_track_activity_type_id_seq', 1, false);


--
-- Name: t_user_activity_track_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_user_activity_track_id_seq', 1, false);


--
-- Name: t_user_skill_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.t_user_skill_mapping_id_seq', 1, false);


--
-- Name: m_account_type m_account_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_account_type
    ADD CONSTRAINT m_account_type_pkey PRIMARY KEY (id);


--
-- Name: m_activity_sub_type m_activity_sub_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_sub_type
    ADD CONSTRAINT m_activity_sub_type_pkey PRIMARY KEY (id);


--
-- Name: m_activity_type m_activity_type_activity_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_type
    ADD CONSTRAINT m_activity_type_activity_type_key UNIQUE (activity_type);


--
-- Name: m_activity_type m_activity_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_type
    ADD CONSTRAINT m_activity_type_pkey PRIMARY KEY (id);


--
-- Name: m_companies m_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_companies
    ADD CONSTRAINT m_companies_pkey PRIMARY KEY (id);


--
-- Name: m_course_level m_course_level_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_level
    ADD CONSTRAINT m_course_level_pkey PRIMARY KEY (id);


--
-- Name: m_course_mapping m_course_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_mapping
    ADD CONSTRAINT m_course_mapping_pkey PRIMARY KEY (id);


--
-- Name: m_course m_course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course
    ADD CONSTRAINT m_course_pkey PRIMARY KEY (id);


--
-- Name: m_course_status m_course_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_status
    ADD CONSTRAINT m_course_status_pkey PRIMARY KEY (id);


--
-- Name: m_course_type m_course_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_type
    ADD CONSTRAINT m_course_type_pkey PRIMARY KEY (id);


--
-- Name: m_currency m_currency_currency_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_currency
    ADD CONSTRAINT m_currency_currency_code_key UNIQUE (currency_code);


--
-- Name: m_currency m_currency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_currency
    ADD CONSTRAINT m_currency_pkey PRIMARY KEY (id);


--
-- Name: m_designations m_designations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_designations
    ADD CONSTRAINT m_designations_pkey PRIMARY KEY (id);


--
-- Name: m_education m_education_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_education
    ADD CONSTRAINT m_education_pkey PRIMARY KEY (id);


--
-- Name: m_gender m_gender_gender_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_gender
    ADD CONSTRAINT m_gender_gender_key UNIQUE (gender);


--
-- Name: m_gender m_gender_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_gender
    ADD CONSTRAINT m_gender_pkey PRIMARY KEY (id);


--
-- Name: m_industry m_industry_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_industry
    ADD CONSTRAINT m_industry_name_key UNIQUE (name);


--
-- Name: m_industry m_industry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_industry
    ADD CONSTRAINT m_industry_pkey PRIMARY KEY (id);


--
-- Name: m_institution m_institution_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_institution
    ADD CONSTRAINT m_institution_pkey PRIMARY KEY (institution_id);


--
-- Name: m_item_view m_item_view_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_item_view
    ADD CONSTRAINT m_item_view_pkey PRIMARY KEY (id);


--
-- Name: m_job_application m_job_application_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application
    ADD CONSTRAINT m_job_application_pkey PRIMARY KEY (id);


--
-- Name: m_job_application_status m_job_application_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application_status
    ADD CONSTRAINT m_job_application_status_pkey PRIMARY KEY (id);


--
-- Name: m_job_mode m_job_mode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_mode
    ADD CONSTRAINT m_job_mode_pkey PRIMARY KEY (id);


--
-- Name: m_job m_job_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job
    ADD CONSTRAINT m_job_pkey PRIMARY KEY (id);


--
-- Name: m_job_type m_job_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_type
    ADD CONSTRAINT m_job_type_pkey PRIMARY KEY (id);


--
-- Name: m_organisation m_organisation_organisation_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation
    ADD CONSTRAINT m_organisation_organisation_name_key UNIQUE (organisation_name);


--
-- Name: m_organisation m_organisation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation
    ADD CONSTRAINT m_organisation_pkey PRIMARY KEY (id);


--
-- Name: m_post m_post_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_post
    ADD CONSTRAINT m_post_pkey PRIMARY KEY (id);


--
-- Name: m_report_activity m_report_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_activity
    ADD CONSTRAINT m_report_activity_pkey PRIMARY KEY (id);


--
-- Name: m_report_profile m_report_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_profile
    ADD CONSTRAINT m_report_profile_pkey PRIMARY KEY (id);


--
-- Name: m_skills m_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_skills
    ADD CONSTRAINT m_skills_pkey PRIMARY KEY (id);


--
-- Name: m_skills m_skills_skill_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_skills
    ADD CONSTRAINT m_skills_skill_name_key UNIQUE (skill_name);


--
-- Name: m_subscription_type m_subscription_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_subscription_type
    ADD CONSTRAINT m_subscription_type_pkey PRIMARY KEY (id);


--
-- Name: m_user m_user_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT m_user_email_key UNIQUE (email);


--
-- Name: t_user_experience m_user_experience_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_experience
    ADD CONSTRAINT m_user_experience_pkey PRIMARY KEY (id);


--
-- Name: m_user m_user_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT m_user_phone_number_key UNIQUE (phone_number);


--
-- Name: m_user m_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT m_user_pkey PRIMARY KEY (id);


--
-- Name: t_course_likes t_course_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_likes
    ADD CONSTRAINT t_course_likes_pkey PRIMARY KEY (id);


--
-- Name: t_course_share t_course_share_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_share
    ADD CONSTRAINT t_course_share_pkey PRIMARY KEY (id);


--
-- Name: t_education_mapping t_education_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_education_mapping
    ADD CONSTRAINT t_education_mapping_pkey PRIMARY KEY (id);


--
-- Name: t_job_mapping t_job_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_mapping
    ADD CONSTRAINT t_job_mapping_pkey PRIMARY KEY (id);


--
-- Name: t_job_share t_job_share_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_share
    ADD CONSTRAINT t_job_share_pkey PRIMARY KEY (id);


--
-- Name: t_mention_tracking t_mention_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_mention_tracking
    ADD CONSTRAINT t_mention_tracking_pkey PRIMARY KEY (id);


--
-- Name: t_post_comment t_post_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_comment
    ADD CONSTRAINT t_post_comment_pkey PRIMARY KEY (id);


--
-- Name: t_post_likes t_post_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_likes
    ADD CONSTRAINT t_post_likes_pkey PRIMARY KEY (id);


--
-- Name: t_post_share t_post_share_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_share
    ADD CONSTRAINT t_post_share_pkey PRIMARY KEY (id);


--
-- Name: t_post_tracking t_post_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_tracking
    ADD CONSTRAINT t_post_tracking_pkey PRIMARY KEY (id);


--
-- Name: t_report_action t_report_action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_report_action
    ADD CONSTRAINT t_report_action_pkey PRIMARY KEY (id);


--
-- Name: t_tag_tracking t_tag_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_tag_tracking
    ADD CONSTRAINT t_tag_tracking_pkey PRIMARY KEY (id);


--
-- Name: t_user_activity_track t_user_activity_track_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_activity_track
    ADD CONSTRAINT t_user_activity_track_pkey PRIMARY KEY (id);


--
-- Name: t_user_skill_mapping t_user_skill_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_skill_mapping
    ADD CONSTRAINT t_user_skill_mapping_pkey PRIMARY KEY (id);


--
-- Name: m_user fk_account_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT fk_account_type FOREIGN KEY (account_type) REFERENCES public.m_account_type(id);


--
-- Name: m_activity_sub_type fk_m_activity_sub_type_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_activity_sub_type
    ADD CONSTRAINT fk_m_activity_sub_type_parent FOREIGN KEY (parent_id) REFERENCES public.m_activity_type(id);


--
-- Name: m_course fk_m_course_level; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course
    ADD CONSTRAINT fk_m_course_level FOREIGN KEY (level) REFERENCES public.m_course_level(id);


--
-- Name: m_course_mapping fk_m_course_mapping_course; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_mapping
    ADD CONSTRAINT fk_m_course_mapping_course FOREIGN KEY (course_id) REFERENCES public.m_course(id);


--
-- Name: m_course_mapping fk_m_course_mapping_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course_mapping
    ADD CONSTRAINT fk_m_course_mapping_user FOREIGN KEY (user_id) REFERENCES public.m_user(id);


--
-- Name: m_course fk_m_course_status; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course
    ADD CONSTRAINT fk_m_course_status FOREIGN KEY (status) REFERENCES public.m_course_status(id);


--
-- Name: m_course fk_m_course_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course
    ADD CONSTRAINT fk_m_course_type FOREIGN KEY (course_type) REFERENCES public.m_course_type(id);


--
-- Name: m_job_application fk_m_job_application_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application
    ADD CONSTRAINT fk_m_job_application_job FOREIGN KEY (job_id) REFERENCES public.m_job(id);


--
-- Name: m_job_application fk_m_job_application_status; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job_application
    ADD CONSTRAINT fk_m_job_application_status FOREIGN KEY (status) REFERENCES public.m_job_application_status(id);


--
-- Name: m_job fk_m_job_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job
    ADD CONSTRAINT fk_m_job_company FOREIGN KEY (organisation_id) REFERENCES public.m_organisation(id);


--
-- Name: m_job fk_m_job_currency; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job
    ADD CONSTRAINT fk_m_job_currency FOREIGN KEY (pay_currency) REFERENCES public.m_currency(id);


--
-- Name: m_job fk_m_job_designation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job
    ADD CONSTRAINT fk_m_job_designation FOREIGN KEY (designation_id) REFERENCES public.m_designations(id);


--
-- Name: m_job fk_m_job_mode; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job
    ADD CONSTRAINT fk_m_job_mode FOREIGN KEY (job_mode) REFERENCES public.m_job_mode(id);


--
-- Name: m_job fk_m_job_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_job
    ADD CONSTRAINT fk_m_job_type FOREIGN KEY (job_type) REFERENCES public.m_job_type(id);


--
-- Name: m_organisation fk_m_organisation_currency; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation
    ADD CONSTRAINT fk_m_organisation_currency FOREIGN KEY (pay_currency) REFERENCES public.m_currency(id);


--
-- Name: m_organisation fk_m_organisation_industry; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_organisation
    ADD CONSTRAINT fk_m_organisation_industry FOREIGN KEY (industry_id) REFERENCES public.m_industry(id);


--
-- Name: m_report_activity fk_m_report_activity_reporter; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_activity
    ADD CONSTRAINT fk_m_report_activity_reporter FOREIGN KEY (reporter_id) REFERENCES public.m_user(id);


--
-- Name: m_report_profile fk_m_report_profile_reported; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_profile
    ADD CONSTRAINT fk_m_report_profile_reported FOREIGN KEY (reported_id) REFERENCES public.m_user(id);


--
-- Name: m_report_profile fk_m_report_profile_reporter; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_report_profile
    ADD CONSTRAINT fk_m_report_profile_reporter FOREIGN KEY (reporter_id) REFERENCES public.m_user(id);


--
-- Name: m_course fk_m_subscription_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_course
    ADD CONSTRAINT fk_m_subscription_type FOREIGN KEY (subscription_type) REFERENCES public.m_subscription_type(id);


--
-- Name: t_course_likes fk_t_course_likes_course; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_likes
    ADD CONSTRAINT fk_t_course_likes_course FOREIGN KEY (course_id) REFERENCES public.m_course(id);


--
-- Name: t_course_share fk_t_course_share_course; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_share
    ADD CONSTRAINT fk_t_course_share_course FOREIGN KEY (course_id) REFERENCES public.m_course(id);


--
-- Name: t_course_share fk_t_course_share_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_course_share
    ADD CONSTRAINT fk_t_course_share_user_id FOREIGN KEY (user_id) REFERENCES public.m_user(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: t_education_mapping fk_t_education_mapping_education; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_education_mapping
    ADD CONSTRAINT fk_t_education_mapping_education FOREIGN KEY (education_id) REFERENCES public.m_education(id);


--
-- Name: t_education_mapping fk_t_education_mapping_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_education_mapping
    ADD CONSTRAINT fk_t_education_mapping_user FOREIGN KEY (user_id) REFERENCES public.m_user(id);


--
-- Name: t_job_mapping fk_t_job_mapping_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_mapping
    ADD CONSTRAINT fk_t_job_mapping_job FOREIGN KEY (job_id) REFERENCES public.m_job(id);


--
-- Name: t_job_mapping fk_t_job_mapping_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_mapping
    ADD CONSTRAINT fk_t_job_mapping_user FOREIGN KEY (posted_by) REFERENCES public.m_user(id);


--
-- Name: t_job_share fk_t_job_share_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_share
    ADD CONSTRAINT fk_t_job_share_job FOREIGN KEY (job_id) REFERENCES public.m_job(id);


--
-- Name: t_job_share fk_t_job_share_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_job_share
    ADD CONSTRAINT fk_t_job_share_user FOREIGN KEY (shared_by) REFERENCES public.m_user(id);


--
-- Name: t_post_comment fk_t_post_comment_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_comment
    ADD CONSTRAINT fk_t_post_comment_parent FOREIGN KEY (parent_comment_id) REFERENCES public.t_post_comment(id);


--
-- Name: t_post_comment fk_t_post_comment_post; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_comment
    ADD CONSTRAINT fk_t_post_comment_post FOREIGN KEY (post_id) REFERENCES public.m_post(id);


--
-- Name: t_post_likes fk_t_post_likes_post; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_likes
    ADD CONSTRAINT fk_t_post_likes_post FOREIGN KEY (post_id) REFERENCES public.m_post(id);


--
-- Name: t_post_share fk_t_post_share_post; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_share
    ADD CONSTRAINT fk_t_post_share_post FOREIGN KEY (post_id) REFERENCES public.m_post(id);


--
-- Name: t_post_tracking fk_t_post_tracking_post; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_tracking
    ADD CONSTRAINT fk_t_post_tracking_post FOREIGN KEY (post_id) REFERENCES public.m_post(id);


--
-- Name: t_post_tracking fk_t_post_tracking_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_post_tracking
    ADD CONSTRAINT fk_t_post_tracking_user FOREIGN KEY (posted_by) REFERENCES public.m_user(id);


--
-- Name: t_report_action fk_t_report_action_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_report_action
    ADD CONSTRAINT fk_t_report_action_user FOREIGN KEY (action_by) REFERENCES public.m_user(id);


--
-- Name: m_user m_user_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT m_user_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.m_user(id) NOT VALID;


--
-- Name: t_user_experience m_user_experience_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_experience
    ADD CONSTRAINT m_user_experience_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.m_companies(id) ON DELETE CASCADE;


--
-- Name: t_user_experience m_user_experience_designation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_experience
    ADD CONSTRAINT m_user_experience_designation_id_fkey FOREIGN KEY (designation_id) REFERENCES public.m_designations(id) ON DELETE CASCADE;


--
-- Name: t_user_experience m_user_experience_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_experience
    ADD CONSTRAINT m_user_experience_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.m_user(id) ON DELETE CASCADE;


--
-- Name: m_user m_user_gender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT m_user_gender_fkey FOREIGN KEY (gender) REFERENCES public.m_gender(id) NOT VALID;


--
-- Name: m_user m_user_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.m_user
    ADD CONSTRAINT m_user_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.m_user(id) NOT VALID;


--
-- Name: t_user_activity_track t_user_activity_track_activity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_activity_track
    ADD CONSTRAINT t_user_activity_track_activity_type_id_fkey FOREIGN KEY (activity_type_id) REFERENCES public.m_activity_type(id) ON DELETE CASCADE;


--
-- Name: t_user_activity_track t_user_activity_track_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_activity_track
    ADD CONSTRAINT t_user_activity_track_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.m_user(id) ON DELETE CASCADE;


--
-- Name: t_user_skill_mapping t_user_skill_mapping_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_skill_mapping
    ADD CONSTRAINT t_user_skill_mapping_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.m_skills(id) ON DELETE CASCADE;


--
-- Name: t_user_skill_mapping t_user_skill_mapping_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_user_skill_mapping
    ADD CONSTRAINT t_user_skill_mapping_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.m_user(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

