/* ============================================================
   RaceDay Event Management System
   SQL Server Database Script - PROG6212 PoE Part 1
   ============================================================
   Run on a clean SQL Server instance in SSMS.
   Creates: Role, [User], Event, Category, Enrolment, Result
   ============================================================ */

IF DB_ID('RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END
GO

USE RaceDayDB;
GO

/* ---------- Drop tables if they already exist (clean rebuild) ---------- */
IF OBJECT_ID('dbo.Result', 'U') IS NOT NULL DROP TABLE dbo.Result;
IF OBJECT_ID('dbo.Enrolment', 'U') IS NOT NULL DROP TABLE dbo.Enrolment;
IF OBJECT_ID('dbo.Category', 'U') IS NOT NULL DROP TABLE dbo.Category;
IF OBJECT_ID('dbo.Event', 'U') IS NOT NULL DROP TABLE dbo.Event;
IF OBJECT_ID('dbo.[User]', 'U') IS NOT NULL DROP TABLE dbo.[User];
IF OBJECT_ID('dbo.Role', 'U') IS NOT NULL DROP TABLE dbo.Role;
GO

/* ============================================================
   1. Role  (lookup table: Organiser / Participant)
   ============================================================ */
CREATE TABLE dbo.Role (
    RoleID      INT IDENTITY(1,1) PRIMARY KEY,
    RoleName    VARCHAR(20) NOT NULL UNIQUE
);
GO

/* ============================================================
   2. User  (both Organisers and Participants, distinguished by RoleID)
   ============================================================ */
CREATE TABLE dbo.[User] (
    UserID              INT IDENTITY(1,1) PRIMARY KEY,
    FullName            VARCHAR(100) NOT NULL,
    Email               VARCHAR(150) NOT NULL UNIQUE,
    PasswordHash        VARCHAR(255) NOT NULL,
    ContactNumber       VARCHAR(20)  NULL,
    EmergencyContact    VARCHAR(20)  NULL,
    RoleID              INT NOT NULL,
    CreatedDate         DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_User_Role FOREIGN KEY (RoleID) REFERENCES dbo.Role(RoleID)
);
GO

/* ============================================================
   3. Event  (created and owned by an Organiser)
   ============================================================ */
CREATE TABLE dbo.Event (
    EventID         INT IDENTITY(1,1) PRIMARY KEY,
    EventName       VARCHAR(150) NOT NULL,
    Description     VARCHAR(500) NULL,
    EventDate       DATE NOT NULL,
    Location        VARCHAR(150) NOT NULL,
    DistanceKm      DECIMAL(5,2) NOT NULL,
    EventType       VARCHAR(20) NOT NULL CHECK (EventType IN ('Running','Walking','Cycling')),
    MaxParticipants INT NOT NULL DEFAULT 100,
    Status          VARCHAR(20) NOT NULL DEFAULT 'Published'
                    CHECK (Status IN ('Draft','Published','Cancelled','Completed')),
    OrganiserID     INT NOT NULL,
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserID) REFERENCES dbo.[User](UserID)
);
GO

/* ============================================================
   4. Category  (belongs to one Event)
   ============================================================ */
CREATE TABLE dbo.Category (
    CategoryID      INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName    VARCHAR(50) NOT NULL,
    MinAge          INT NOT NULL DEFAULT 0,
    MaxAge          INT NOT NULL DEFAULT 99,
    Fee             DECIMAL(8,2) NOT NULL DEFAULT 0,
    EventID         INT NOT NULL,
    CONSTRAINT FK_Category_Event FOREIGN KEY (EventID) REFERENCES dbo.Event(EventID)
);
GO

/* ============================================================
   5. Enrolment  (associative entity resolving the Participant <-> Event
      <-> Category many-to-many relationships)
   ============================================================ */
CREATE TABLE dbo.Enrolment (
    EnrolmentID     INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentDate   DATETIME NOT NULL DEFAULT GETDATE(),
    Status          VARCHAR(20) NOT NULL DEFAULT 'Confirmed'
                    CHECK (Status IN ('Pending','Confirmed','Cancelled')),
    ParticipantID   INT NOT NULL,
    EventID         INT NOT NULL,
    CategoryID      INT NOT NULL,
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantID) REFERENCES dbo.[User](UserID),
    CONSTRAINT FK_Enrolment_Event FOREIGN KEY (EventID) REFERENCES dbo.Event(EventID),
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (CategoryID) REFERENCES dbo.Category(CategoryID),
    CONSTRAINT UQ_Enrolment_ParticipantEvent UNIQUE (ParticipantID, EventID)
);
GO

/* ============================================================
   6. Result  (one-to-one with Enrolment; captured by an Organiser)
   ============================================================ */
CREATE TABLE dbo.Result (
    ResultID                INT IDENTITY(1,1) PRIMARY KEY,
    FinishTime              TIME NULL,
    FinishPosition          INT NULL,
    CapturedDate            DATETIME NOT NULL DEFAULT GETDATE(),
    EnrolmentID             INT NOT NULL UNIQUE,
    CapturedByOrganiserID   INT NOT NULL,
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentID) REFERENCES dbo.Enrolment(EnrolmentID),
    CONSTRAINT FK_Result_Organiser FOREIGN KEY (CapturedByOrganiserID) REFERENCES dbo.[User](UserID)
);
GO

/* ============================================================
   SEED DATA
   ============================================================ */

-- Roles
INSERT INTO dbo.Role (RoleName) VALUES ('Organiser'), ('Participant');
GO

-- 2 Organisers + 2 Participants
INSERT INTO dbo.[User] (FullName, Email, PasswordHash, ContactNumber, EmergencyContact, RoleID)
VALUES
('Thabo Nkosi',   'thabo.nkosi@raceday.co.za',   'HASHED_PWD_1', '0821234567', NULL, 1),
('Lindiwe Dube',  'lindiwe.dube@raceday.co.za',  'HASHED_PWD_2', '0837654321', NULL, 1),
('Sipho Mokoena', 'sipho.mokoena@example.com',   'HASHED_PWD_3', '0731122334', '0827654321', 2),
('Amahle Botha',  'amahle.botha@example.com',    'HASHED_PWD_4', '0765544332', '0839988776', 2);
GO

-- 3 Events (owned by the two Organisers)
INSERT INTO dbo.Event (EventName, Description, EventDate, Location, DistanceKm, EventType, MaxParticipants, Status, OrganiserID)
VALUES
('Johannesburg City 10K', 'Annual road running race through the Johannesburg CBD.', '2026-10-18', 'Johannesburg, Gauteng', 10.0, 'Running', 500, 'Published', 1),
('Cape Town Cycle Classic', 'Scenic cycling event along the Cape Peninsula.', '2026-11-08', 'Cape Town, Western Cape', 109.0, 'Cycling', 800, 'Published', 2),
('Durban Beachfront Walk', 'Family-friendly walking event along the Durban beachfront.', '2026-09-27', 'Durban, KwaZulu-Natal', 5.0, 'Walking', 300, 'Published', 1);
GO

-- Categories for each Event
INSERT INTO dbo.Category (CategoryName, MinAge, MaxAge, Fee, EventID)
VALUES
('Open Race', 18, 65, 150.00, 1),
('Junior Race', 10, 17, 80.00, 1),
('Seeded Riders', 18, 70, 450.00, 2),
('Fun Ride', 12, 99, 250.00, 2),
('Family Walk', 5, 99, 50.00, 3);
GO

-- Sample Enrolments (Participants entering Events/Categories)
INSERT INTO dbo.Enrolment (Status, ParticipantID, EventID, CategoryID)
VALUES
('Confirmed', 3, 1, 1),
('Confirmed', 4, 1, 1),
('Confirmed', 3, 2, 3),
('Pending',   4, 3, 5);
GO

-- Sample Results (captured by an Organiser for a completed enrolment)
INSERT INTO dbo.Result (FinishTime, FinishPosition, EnrolmentID, CapturedByOrganiserID)
VALUES
('00:42:13', 5, 1, 1),
('00:45:02', 12, 2, 1);
GO
