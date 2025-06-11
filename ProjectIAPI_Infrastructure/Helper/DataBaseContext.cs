using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Npgsql;
using ProjectIAPI_Core.ViewModels; // Updated to use underscore
using ProjectIAPI_Infrastructure.Models; // Updated to use underscore
using System.Text.Json;

namespace ProjectIAPI_Infrastructure.Helper // Updated to use underscore
{
    public partial class DataBaseContext : DbContext
    {
        private readonly IConfiguration _configuration;

        public DataBaseContext()
        {
        }

        public DataBaseContext(DbContextOptions<DataBaseContext> options, IConfiguration configuration) : base(options)
        {
            _configuration = configuration;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                var connectionString = _configuration.GetConnectionString("DataBaseContext");
                var dataSourceBuilder = new NpgsqlDataSourceBuilder(connectionString);
                optionsBuilder.UseNpgsql(dataSourceBuilder.Build());
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure fn_validate_account as a keyless entity
            modelBuilder.Entity<fn_validate_account>()
                .HasNoKey()
                .ToFunction("fn_validate_account");

            // Configure fn_forget_password as a keyless entity
            modelBuilder.Entity<fn_forget_password>()
                .HasNoKey()
                .ToFunction("fn_forget_password");

            // Configure fn_change_password as a keyless entity
            modelBuilder.Entity<fn_change_password>()
                .HasNoKey()
                .ToFunction("fn_change_password");

            // Configure fn_education_insert_update as a keyless entity
            modelBuilder.Entity<fn_education_insert_update>()
                .HasNoKey()
                .ToFunction("fn_education_insert_update");

            // Configure fn_experience_insert_update as a keyless entity
            modelBuilder.Entity<fn_experience_insert_update>()
                .HasNoKey()
                .ToFunction("fn_experience_insert_update");

            // Configure fn_m_user_insert_update as a keyless entity
            modelBuilder.Entity<fn_m_user_insert_update>()
                .HasNoKey()
                .ToFunction("fn_m_user_insert_update");

            // Configure fn_fetch_user_profile as a keyless entity
            modelBuilder.Entity<fn_fetch_user_profile>()
                .HasNoKey()
                .ToFunction("fn_fetch_user_profile");

            // Configure JSONB mapping for resultdata in fn_fetch_user_profile
            modelBuilder.Entity<fn_fetch_user_profile>()
                .Property(e => e.resultdata)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions)null),
                    v => JsonSerializer.Deserialize<ResultData>(v, (JsonSerializerOptions)null));

            // Configure m_user
            modelBuilder.Entity<m_user>()
                .HasKey(u => u.id); // Primary key

            OnModelCreatingPartial(modelBuilder);
        }

        public DbSet<m_user> m_user { get; set; }
        public DbSet<fn_validate_account> fn_validate_account { get; set; }
        public DbSet<fn_m_user_insert_update> fn_m_user_insert_updates { get; set; }
        public DbSet<fn_forget_password> fn_forget_password { get; set; }
        public DbSet<fn_change_password> fn_change_password { get; set; }
        public DbSet<fn_education_insert_update> fn_education_insert_update { get; set; }
        public DbSet<fn_experience_insert_update> fn_experience_insert_update { get; set; }
        public DbSet<fn_fetch_user_profile> fn_fetch_user_profile { get; set; }

        public async Task<fn_fetch_user_profile> FetchUserProfileAsync(long userId)
        {
            var result = await fn_fetch_user_profile
                .FromSqlRaw("SELECT * FROM public.fn_fetch_user_profile({0})", userId)
                .AsNoTracking()
                .FirstOrDefaultAsync();
            return result;
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}