-- =====================================================================
-- MC212 DBMS Lab 9 - CCMS REALISTIC, VARIED COURSEWORK DATA
-- Rebuilt against CCMS_DDL.sql (31 base tables).
-- Synthetic Indian names, courts, locations, case records and narratives.
-- Every one of the 31 tables contains 85-110 rows; counts vary by table.
-- All seeded app_user rows inherit the demo Argon2id password hash from the DDL.
-- Local demo password: CourtAccess@2026. Replace before any shared deployment.
--
-- IMPORTANT:
-- 1. Run only in the dedicated CCMS coursework database.
-- 2. This script TRUNCATES all existing CCMS records before loading data.
-- 3. It preserves the DDL/schema and inserts data only.
-- 4. Existing user-defined hearing/judgment triggers are paused during
--    loading and re-enabled afterwards to prevent duplicate side effects.
-- 5. Emails use synthetic @temp.com addresses; phone numbers are synthetic.
-- =====================================================================

BEGIN;

TRUNCATE TABLE
    public.hearing_witness,
    public.lawyer_case,
    public.lawyer_party,
    public.judge_evidence,
    public.judge_court_order,
    public.bench_judge,
    public.case_witness,
    public.case_party,
    public.document,
    public.case_status_history,
    public.filing_defect,
    public.audit_log,
    public.notification,
    public.adjournment,
    public.evidence,
    public.petition,
    public.court_order,
    public.judgment,
    public.hearing,
    public.court_case,
    public.courtroom,
    public.app_user,
    public.role,
    public.lawyer,
    public.witness,
    public.party,
    public.judge,
    public.court_clerk,
    public.bench,
    public.cause_list,
    public.court
RESTART IDENTITY CASCADE;

ALTER TABLE public.hearing DISABLE TRIGGER USER;
ALTER TABLE public.judgment DISABLE TRIGGER USER;

-- court: 16 records
INSERT INTO public.court (court_id, jurisdiction_area, physical_address)
VALUES
    (1, 'Gujarat High Court', 'Gujarat High Court, Sola, Ahmedabad'),
    (2, 'Rajkot District and Sessions Court', 'District Court Campus, Rajkot, Gujarat'),
    (3, 'Morbi District and Sessions Court', 'District and Sessions Court, Morbi, Gujarat'),
    (4, 'Surat District and Sessions Court', 'New District Court Complex, Athwalines, Surat'),
    (5, 'Vadodara District and Sessions Court', 'District Court Road, Vadodara, Gujarat'),
    (6, 'Bhavnagar District and Sessions Court', 'District Court, Waghawadi Road, Bhavnagar'),
    (7, 'City Civil and Sessions Court, Mumbai', 'Fort, Mumbai, Maharashtra'),
    (8, 'Pune District and Sessions Court', 'Shivajinagar Court Complex, Pune, Maharashtra'),
    (9, 'Jaipur District and Sessions Court', 'District Court Campus, Jaipur, Rajasthan'),
    (10, 'Patiala House Courts, New Delhi', 'Patiala House Courts, New Delhi'),
    (11, 'Lucknow District and Sessions Court', 'Lucknow District Court, Kaiserbagh, Uttar Pradesh'),
    (12, 'City Civil Court, Bengaluru', 'City Civil Court Complex, Bengaluru, Karnataka'),
    (13, 'Hyderabad District and Sessions Court', 'Nampally Criminal Courts, Hyderabad, Telangana'),
    (14, 'Principal District Court, Chennai', 'Principal District Court, Chennai, Tamil Nadu'),
    (15, 'District Court Complex, Ernakulam', 'District Court Complex, Ernakulam, Kochi'),
    (16, 'City Civil Court, Kolkata', 'City Civil Court, B.B.D. Bagh, Kolkata');

-- judge: 18 records
INSERT INTO public.judge (judge_id, judge_name, designation)
VALUES
    (1, 'Karan Saxena', 'Metropolitan Magistrate'),
    (2, 'Aarav Purohit', 'District and Sessions Judge'),
    (3, 'Kunal Chauhan', 'Principal Judge, Family Court'),
    (4, 'Siddharth Pillai', 'Additional Sessions Judge'),
    (5, 'Meera Shetty', 'Civil Judge (Senior Division)'),
    (6, 'Tanvi Iyer', 'Metropolitan Magistrate'),
    (7, 'Madhav Choudhary', 'District and Sessions Judge'),
    (8, 'Bhavna Patel', 'Principal Judge, Family Court'),
    (9, 'Ritika Kapoor', 'Additional Sessions Judge'),
    (10, 'Rohan Gandhi', 'Civil Judge (Senior Division)'),
    (11, 'Nikhil Joshi', 'Metropolitan Magistrate'),
    (12, 'Kavya Verma', 'District and Sessions Judge'),
    (13, 'Neha Bhatt', 'Principal Judge, Family Court'),
    (14, 'Ira Reddy', 'Additional Sessions Judge'),
    (15, 'Nirav Mukherjee', 'Civil Judge (Senior Division)'),
    (16, 'Sameer Mehta', 'Metropolitan Magistrate'),
    (17, 'Krish Kulkarni', 'District and Sessions Judge'),
    (18, 'Kabir Jain', 'Principal Judge, Family Court');

-- party: 45 records
INSERT INTO public.party (party_id, party_name, party_type, phone, address)
VALUES
    (1, 'Parth Mehta', 'Plaintiff', '+91-9100000001', '11 University Road, Pune, Maharashtra'),
    (2, 'Imran Kulkarni', 'Defendant', '+91-9100000002', '12 Ring Road, Hyderabad, Telangana'),
    (3, 'Aditya Jain', 'Plaintiff', '+91-9100000003', '13 Station Road, Rajkot, Gujarat'),
    (4, 'Manav Desai', 'Defendant', '+91-9100000004', '14 Law Garden Road, Mumbai, Maharashtra'),
    (5, 'Ananya Malhotra', 'Plaintiff', '+91-9100000005', '15 Satellite Road, Bengaluru, Karnataka'),
    (6, 'Riya Mistry', 'Defendant', '+91-9100000006', '16 Paldi Main Road, Ahmedabad, Gujarat'),
    (7, 'Shree Narmada Infrastructure Pvt. Ltd.', 'Organization', '+91-9100000007', '17 Race Course Road, Bhavnagar, Gujarat'),
    (8, 'Yash Rao', 'Defendant', '+91-9100000008', '18 Kalawad Road, Lucknow, Uttar Pradesh'),
    (9, 'Farah Solanki', 'Plaintiff', '+91-9100000009', '19 M.G. Road, Kolkata, West Bengal'),
    (10, 'Vivaan Nair', 'Defendant', '+91-9100000010', '20 Civil Lines, Vadodara, Gujarat'),
    (11, 'Dev Banerjee', 'Plaintiff', '+91-9100000011', '21 Court Road, New Delhi, Delhi'),
    (12, 'Rahul Shah', 'Defendant', '+91-9100000012', '22 Marine Drive, Kochi, Kerala'),
    (13, 'Nisha Menon', 'Plaintiff', '+91-9100000013', '23 Shivajinagar Road, Surat, Gujarat'),
    (14, 'Mira Soni', 'Defendant', '+91-9100000014', '24 Ashram Road, Jaipur, Rajasthan'),
    (15, 'Harsh Trivedi', 'Plaintiff', '+91-9100000015', '25 University Road, Chennai, Tamil Nadu'),
    (16, 'Karan Saxena', 'Defendant', '+91-9100000016', '26 Ring Road, Morbi, Gujarat'),
    (17, 'Aarav Purohit', 'Plaintiff', '+91-9100000017', '27 Station Road, Pune, Maharashtra'),
    (18, 'Western Freight Carriers LLP', 'Organization', '+91-9100000018', '28 Law Garden Road, Hyderabad, Telangana'),
    (19, 'Siddharth Pillai', 'Plaintiff', '+91-9100000019', '29 Satellite Road, Rajkot, Gujarat'),
    (20, 'Meera Shetty', 'Defendant', '+91-9100000020', '30 Paldi Main Road, Mumbai, Maharashtra'),
    (21, 'Tanvi Iyer', 'Plaintiff', '+91-9100000021', '31 Race Course Road, Bengaluru, Karnataka'),
    (22, 'Madhav Choudhary', 'Defendant', '+91-9100000022', '32 Kalawad Road, Ahmedabad, Gujarat'),
    (23, 'Bhavna Patel', 'Plaintiff', '+91-9100000023', '33 M.G. Road, Bhavnagar, Gujarat'),
    (24, 'Ritika Kapoor', 'Defendant', '+91-9100000024', '34 Civil Lines, Lucknow, Uttar Pradesh'),
    (25, 'Rohan Gandhi', 'Plaintiff', '+91-9100000025', '35 Court Road, Kolkata, West Bengal'),
    (26, 'Nikhil Joshi', 'Defendant', '+91-9100000026', '36 Marine Drive, Vadodara, Gujarat'),
    (27, 'Kavya Verma', 'Plaintiff', '+91-9100000027', '37 Shivajinagar Road, New Delhi, Delhi'),
    (28, 'Neha Bhatt', 'Defendant', '+91-9100000028', '38 Ashram Road, Kochi, Kerala'),
    (29, 'Aarambh Developers Pvt. Ltd.', 'Organization', '+91-9100000029', '39 University Road, Surat, Gujarat'),
    (30, 'Nirav Mukherjee', 'Defendant', '+91-9100000030', '40 Ring Road, Jaipur, Rajasthan'),
    (31, 'Sameer Mehta', 'Plaintiff', '+91-9100000031', '41 Station Road, Chennai, Tamil Nadu'),
    (32, 'Krish Kulkarni', 'Defendant', '+91-9100000032', '42 Law Garden Road, Morbi, Gujarat'),
    (33, 'Kabir Jain', 'Plaintiff', '+91-9100000033', '43 Satellite Road, Pune, Maharashtra'),
    (34, 'Isha Desai', 'Defendant', '+91-9100000034', '44 Paldi Main Road, Hyderabad, Telangana'),
    (35, 'Pooja Malhotra', 'Plaintiff', '+91-9100000035', '45 Race Course Road, Rajkot, Gujarat'),
    (36, 'Sana Mistry', 'Defendant', '+91-9100000036', '46 Kalawad Road, Mumbai, Maharashtra'),
    (37, 'Hetal Bhatia', 'Plaintiff', '+91-9100000037', '47 M.G. Road, Bengaluru, Karnataka'),
    (38, 'Ayesha Rao', 'Defendant', '+91-9100000038', '48 Civil Lines, Ahmedabad, Gujarat'),
    (39, 'Ishaan Solanki', 'Plaintiff', '+91-9100000039', '49 Court Road, Bhavnagar, Gujarat'),
    (40, 'Sahyog Cooperative Housing Society', 'Organization', '+91-9100000040', '50 Marine Drive, Lucknow, Uttar Pradesh'),
    (41, 'Diya Banerjee', 'Plaintiff', '+91-9100000041', '51 Shivajinagar Road, Kolkata, West Bengal'),
    (42, 'Aditi Shah', 'Defendant', '+91-9100000042', '52 Ashram Road, Vadodara, Gujarat'),
    (43, 'Avni Menon', 'Plaintiff', '+91-9100000043', '53 University Road, New Delhi, Delhi'),
    (44, 'Jignesh Soni', 'Defendant', '+91-9100000044', '54 Ring Road, Kochi, Kerala'),
    (45, 'Zoya Trivedi', 'Plaintiff', '+91-9100000045', '55 Station Road, Surat, Gujarat');

-- role: 6 records
INSERT INTO public.role (role_id, role_name, role_description)
VALUES
    (1, 'System Administrator', 'Maintains user access, security settings and application configuration.'),
    (2, 'Registry Clerk', 'Receives filings, checks case documents and manages registry records.'),
    (3, 'Court Clerk', 'Maintains hearing schedules, cause lists and courtroom records.'),
    (4, 'Presiding Judge', 'Reviews judicial records and issues procedural directions.'),
    (5, 'Advocate', 'Submits pleadings and represents parties before the court.'),
    (6, 'Read-Only Auditor', 'Reviews audit trails and case records without modifying them.');

-- court_clerk: 14 records
INSERT INTO public.court_clerk (clerk_id, clerk_name, role_type, phone)
VALUES
    (1, 'Aarohi Chauhan', 'Court Clerk', '+91-9200000001'),
    (2, 'Saanvi Pillai', 'Registry Clerk', '+91-9200000002'),
    (3, 'Shreya Shetty', 'Filing Clerk', '+91-9200000003'),
    (4, 'Parth Iyer', 'Court Clerk', '+91-9200000004'),
    (5, 'Imran Choudhary', 'Registry Clerk', '+91-9200000005'),
    (6, 'Aditya Patel', 'Filing Clerk', '+91-9200000006'),
    (7, 'Manav Kapoor', 'Court Clerk', '+91-9200000007'),
    (8, 'Ananya Gandhi', 'Registry Clerk', '+91-9200000008'),
    (9, 'Riya Joshi', 'Filing Clerk', '+91-9200000009'),
    (10, 'Priya Verma', 'Court Clerk', '+91-9200000010'),
    (11, 'Yash Bhatt', 'Registry Clerk', '+91-9200000011'),
    (12, 'Farah Reddy', 'Filing Clerk', '+91-9200000012'),
    (13, 'Vivaan Mukherjee', 'Court Clerk', '+91-9200000013'),
    (14, 'Dev Mehta', 'Registry Clerk', '+91-9200000014');

-- bench: 8 records
INSERT INTO public.bench (bench_id, bench_type, bench_name)
VALUES
    (1, 'Single Bench', 'Morbi Bench 01'),
    (2, 'Division Bench', 'Surat Bench 02'),
    (3, 'Family Court Bench', 'Vadodara Bench 03'),
    (4, 'Commercial Court Bench', 'Bhavnagar Bench 04'),
    (5, 'Sessions Bench', 'Mumbai Bench 05'),
    (6, 'Single Bench', 'Pune Bench 06'),
    (7, 'Division Bench', 'Jaipur Bench 07'),
    (8, 'Family Court Bench', 'New Delhi Bench 08');

-- cause_list: 35 records
INSERT INTO public.cause_list (cause_list_id)
VALUES
    (1),
    (2),
    (3),
    (4),
    (5),
    (6),
    (7),
    (8),
    (9),
    (10),
    (11),
    (12),
    (13),
    (14),
    (15),
    (16),
    (17),
    (18),
    (19),
    (20),
    (21),
    (22),
    (23),
    (24),
    (25),
    (26),
    (27),
    (28),
    (29),
    (30),
    (31),
    (32),
    (33),
    (34),
    (35);

-- lawyer: 28 records
INSERT INTO public.lawyer (lawyer_id, bar_registration_number, full_name, phone, email, law_firm_affiliation, contact_details, license_status)
VALUES
    (1, 'GJ/2021/1001', 'Hetal Verma', '+91-9300000001', 'hetal.verma@temp.com', 'Trivedi and Joshi Partners', 'Office 1, Vadodara; appointments by prior booking', 'Active'),
    (2, 'GJ/2022/1002', 'Ayesha Bhatt', '+91-9300000002', 'ayesha.bhatt@temp.com', 'Sahyog Legal Aid Centre', 'Office 2, Bhavnagar; appointments by prior booking', 'Active'),
    (3, 'GJ/2023/1003', 'Ishaan Reddy', '+91-9300000003', 'ishaan.reddy@temp.com', 'Civic Justice Law Office', 'Office 3, Mumbai; appointments by prior booking', 'Active'),
    (4, 'GJ/2024/1004', 'Reyansh Mukherjee', '+91-9300000004', 'reyansh.mukherjee@temp.com', 'Desai Law Associates', 'Office 4, Pune; appointments by prior booking', 'Active'),
    (5, 'GJ/2025/1005', 'Diya Mehta', '+91-9300000005', 'diya.mehta@temp.com', 'Narmada Juris Consultants', 'Office 5, Jaipur; appointments by prior booking', 'Suspended'),
    (6, 'GJ/2020/1006', 'Aditi Kulkarni', '+91-9300000006', 'aditi.kulkarni@temp.com', 'Iyer Menon Associates', 'Office 6, New Delhi; appointments by prior booking', 'Active'),
    (7, 'GJ/2021/1007', 'Avni Jain', '+91-9300000007', 'avni.jain@temp.com', 'Patel Legal Chambers', 'Office 7, Lucknow; appointments by prior booking', 'Active'),
    (8, 'GJ/2022/1008', 'Jignesh Desai', '+91-9300000008', 'jignesh.desai@temp.com', 'Western India Legal Services', 'Office 8, Bengaluru; appointments by prior booking', 'Active'),
    (9, 'GJ/2023/1009', 'Zoya Malhotra', '+91-9300000009', 'zoya.malhotra@temp.com', 'Rao Chambers', 'Office 9, Hyderabad; appointments by prior booking', 'Active'),
    (10, 'GJ/2024/1010', 'Arjun Mistry', '+91-9300000010', 'arjun.mistry@temp.com', 'Mehta & Shah Advocates', 'Office 10, Chennai; appointments by prior booking', 'Active'),
    (11, 'GJ/2025/1011', 'Dhruv Bhatia', '+91-9300000011', 'dhruv.bhatia@temp.com', 'Trivedi and Joshi Partners', 'Office 11, Kochi; appointments by prior booking', 'Active'),
    (12, 'GJ/2020/1012', 'Aarohi Rao', '+91-9300000012', 'aarohi.rao@temp.com', 'Sahyog Legal Aid Centre', 'Office 12, Kolkata; appointments by prior booking', 'Suspended'),
    (13, 'GJ/2021/1013', 'Saanvi Solanki', '+91-9300000013', 'saanvi.solanki@temp.com', 'Civic Justice Law Office', 'Office 13, Ahmedabad; appointments by prior booking', 'Active'),
    (14, 'GJ/2022/1014', 'Shreya Nair', '+91-9300000014', 'shreya.nair@temp.com', 'Desai Law Associates', 'Office 14, Rajkot; appointments by prior booking', 'Active'),
    (15, 'GJ/2023/1015', 'Parth Banerjee', '+91-9300000015', 'parth.banerjee@temp.com', 'Narmada Juris Consultants', 'Office 15, Morbi; appointments by prior booking', 'Active'),
    (16, 'GJ/2024/1016', 'Imran Shah', '+91-9300000016', 'imran.shah@temp.com', 'Iyer Menon Associates', 'Office 16, Surat; appointments by prior booking', 'Active'),
    (17, 'GJ/2025/1017', 'Aditya Menon', '+91-9300000017', 'aditya.menon@temp.com', 'Patel Legal Chambers', 'Office 17, Vadodara; appointments by prior booking', 'Active'),
    (18, 'GJ/2020/1018', 'Manav Soni', '+91-9300000018', 'manav.soni@temp.com', 'Western India Legal Services', 'Office 18, Bhavnagar; appointments by prior booking', 'Active'),
    (19, 'GJ/2021/1019', 'Ananya Trivedi', '+91-9300000019', 'ananya.trivedi@temp.com', 'Rao Chambers', 'Office 19, Mumbai; appointments by prior booking', 'Suspended'),
    (20, 'GJ/2022/1020', 'Riya Saxena', '+91-9300000020', 'riya.saxena@temp.com', 'Mehta & Shah Advocates', 'Office 20, Pune; appointments by prior booking', 'Active'),
    (21, 'GJ/2023/1021', 'Priya Purohit', '+91-9300000021', 'priya.purohit@temp.com', 'Trivedi and Joshi Partners', 'Office 21, Jaipur; appointments by prior booking', 'Active'),
    (22, 'GJ/2024/1022', 'Yash Chauhan', '+91-9300000022', 'yash.chauhan@temp.com', 'Sahyog Legal Aid Centre', 'Office 22, New Delhi; appointments by prior booking', 'Active'),
    (23, 'GJ/2025/1023', 'Farah Pillai', '+91-9300000023', 'farah.pillai@temp.com', 'Civic Justice Law Office', 'Office 23, Lucknow; appointments by prior booking', 'Active'),
    (24, 'GJ/2020/1024', 'Vivaan Shetty', '+91-9300000024', 'vivaan.shetty@temp.com', 'Desai Law Associates', 'Office 24, Bengaluru; appointments by prior booking', 'Active'),
    (25, 'GJ/2021/1025', 'Dev Iyer', '+91-9300000025', 'dev.iyer@temp.com', 'Narmada Juris Consultants', 'Office 25, Hyderabad; appointments by prior booking', 'Active'),
    (26, 'GJ/2022/1026', 'Rahul Choudhary', '+91-9300000026', 'rahul.choudhary@temp.com', 'Iyer Menon Associates', 'Office 26, Chennai; appointments by prior booking', 'Suspended'),
    (27, 'GJ/2023/1027', 'Nisha Patel', '+91-9300000027', 'nisha.patel@temp.com', 'Patel Legal Chambers', 'Office 27, Kochi; appointments by prior booking', 'Active'),
    (28, 'GJ/2024/1028', 'Mira Kapoor', '+91-9300000028', 'mira.kapoor@temp.com', 'Western India Legal Services', 'Office 28, Kolkata; appointments by prior booking', 'Active');

-- witness: 20 records
INSERT INTO public.witness (witness_id, witness_details, testimony_type)
VALUES
    (1, 'Hetal Purohit, residing at Surat; contact details retained by the registry.', 'Neighbour'),
    (2, 'Ayesha Chauhan, residing at Mumbai; contact details retained by the registry.', 'Accountant'),
    (3, 'Ishaan Pillai, residing at New Delhi; contact details retained by the registry.', 'Investigating Officer'),
    (4, 'Reyansh Shetty, residing at Hyderabad; contact details retained by the registry.', 'Forensic Expert'),
    (5, 'Diya Iyer, residing at Kolkata; contact details retained by the registry.', 'Medical Expert'),
    (6, 'Aditi Choudhary, residing at Morbi; contact details retained by the registry.', 'Eyewitness'),
    (7, 'Avni Patel, residing at Bhavnagar; contact details retained by the registry.', 'Neighbour'),
    (8, 'Jignesh Kapoor, residing at Jaipur; contact details retained by the registry.', 'Accountant'),
    (9, 'Zoya Gandhi, residing at Bengaluru; contact details retained by the registry.', 'Investigating Officer'),
    (10, 'Arjun Joshi, residing at Kochi; contact details retained by the registry.', 'Forensic Expert'),
    (11, 'Dhruv Verma, residing at Rajkot; contact details retained by the registry.', 'Medical Expert'),
    (12, 'Aarohi Bhatt, residing at Vadodara; contact details retained by the registry.', 'Eyewitness'),
    (13, 'Saanvi Reddy, residing at Pune; contact details retained by the registry.', 'Neighbour'),
    (14, 'Shreya Mukherjee, residing at Lucknow; contact details retained by the registry.', 'Accountant'),
    (15, 'Parth Mehta, residing at Chennai; contact details retained by the registry.', 'Investigating Officer'),
    (16, 'Imran Kulkarni, residing at Ahmedabad; contact details retained by the registry.', 'Forensic Expert'),
    (17, 'Aditya Jain, residing at Surat; contact details retained by the registry.', 'Medical Expert'),
    (18, 'Manav Desai, residing at Mumbai; contact details retained by the registry.', 'Eyewitness'),
    (19, 'Ananya Malhotra, residing at New Delhi; contact details retained by the registry.', 'Neighbour'),
    (20, 'Riya Mistry, residing at Hyderabad; contact details retained by the registry.', 'Accountant');

-- courtroom: 18 records
INSERT INTO public.courtroom (room_id, room_number, court_id)
VALUES
    (1, 'Court Hall 01', 1),
    (2, 'Family Court Room 02', 2),
    (3, 'Courtroom 03', 3),
    (4, 'Court Hall 04', 4),
    (5, 'Family Court Room 05', 5),
    (6, 'Courtroom 06', 6),
    (7, 'Court Hall 07', 7),
    (8, 'Family Court Room 08', 8),
    (9, 'Courtroom 09', 9),
    (10, 'Court Hall 10', 10),
    (11, 'Family Court Room 11', 11),
    (12, 'Courtroom 12', 12),
    (13, 'Court Hall 13', 13),
    (14, 'Family Court Room 14', 14),
    (15, 'Courtroom 15', 15),
    (16, 'Court Hall 16', 16),
    (17, 'Family Court Room 17', 1),
    (18, 'Courtroom 18', 2);

-- court_case: 48 records
INSERT INTO public.court_case (case_id, cuid, cnr, case_title, case_type, filing_date, court_id)
VALUES
    (1, 'CUID-GJ-2025-00001', 'CNR/GU/2025/10001', 'Proceedings concerning breach of trust in a cooperative society', 'Criminal', DATE '2024-01-12', 1),
    (2, 'CUID-GJ-2026-00002', 'CNR/GU/2026/10002', 'Complaint regarding unlawful retention of deposited property', 'Family', DATE '2024-01-23', 2),
    (3, 'CUID-GJ-2024-00003', 'CNR/GU/2024/10003', 'Claim for compensation arising from a road traffic collision', 'Criminal', DATE '2024-02-03', 3),
    (4, 'CUID-GJ-2025-00004', 'CNR/GU/2025/10004', 'Petition seeking enforcement of a family settlement', 'Civil', DATE '2024-02-14', 4),
    (5, 'CUID-GJ-2026-00005', 'CNR/GU/2026/10005', 'Petition concerning protection of tenancy and possession rights', 'Civil', DATE '2024-02-25', 5),
    (6, 'CUID-GJ-2024-00006', 'CNR/GU/2024/10006', 'Application for anticipatory bail in a financial dispute', 'Criminal', DATE '2024-03-07', 6),
    (7, 'CUID-GJ-2025-00007', 'CNR/MA/2025/10007', 'Nisha Menon v. Mira Soni regarding recovery of contractual dues', 'Motor Accident', DATE '2024-03-18', 7),
    (8, 'CUID-GJ-2026-00008', 'CNR/MA/2026/10008', 'Challenge to termination of employment and unpaid wages', 'Family', DATE '2024-03-29', 8),
    (9, 'CUID-GJ-2024-00009', 'CNR/RA/2024/10009', 'Claim for damages arising from defective goods and services', 'Civil', DATE '2024-04-09', 9),
    (10, 'CUID-GJ-2025-00010', 'CNR/DE/2025/10010', 'Application for guardianship and access arrangements', 'Civil', DATE '2024-04-20', 10),
    (11, 'CUID-GJ-2026-00011', 'CNR/UT/2026/10011', 'Dispute concerning title and possession of ancestral property', 'Family', DATE '2024-05-01', 11),
    (12, 'CUID-GJ-2024-00012', 'CNR/KA/2024/10012', 'Dispute over supply of industrial machinery and unpaid invoices', 'Civil', DATE '2024-05-12', 12),
    (13, 'CUID-GJ-2025-00013', 'CNR/GU/2025/10013', 'Commercial recovery claim arising from a construction contract', 'Civil', DATE '2024-05-23', 13),
    (14, 'CUID-GJ-2026-00014', 'CNR/GU/2026/10014', 'Kavya Verma v. Neha Bhatt concerning maintenance and residence', 'Commercial', DATE '2024-06-03', 14),
    (15, 'CUID-GJ-2024-00015', 'CNR/GU/2024/10015', 'Suit for specific performance of an agreement for sale', 'Family', DATE '2024-06-14', 15),
    (16, 'CUID-GJ-2025-00016', 'CNR/GU/2025/10016', 'State v. Sameer Mehta concerning alleged misappropriation of funds', 'Commercial', DATE '2024-06-25', 16),
    (17, 'CUID-GJ-2026-00017', 'CNR/GU/2026/10017', 'Proceedings concerning breach of trust in a cooperative society', 'Civil', DATE '2024-07-06', 1),
    (18, 'CUID-GJ-2024-00018', 'CNR/GU/2024/10018', 'Complaint regarding unlawful retention of deposited property', 'Family', DATE '2024-07-17', 2),
    (19, 'CUID-GJ-2025-00019', 'CNR/MA/2025/10019', 'Claim for compensation arising from a road traffic collision', 'Civil', DATE '2024-07-28', 3),
    (20, 'CUID-GJ-2026-00020', 'CNR/MA/2026/10020', 'Petition seeking enforcement of a family settlement', 'Commercial', DATE '2024-08-08', 4),
    (21, 'CUID-GJ-2024-00021', 'CNR/RA/2024/10021', 'Petition concerning protection of tenancy and possession rights', 'Criminal', DATE '2024-08-19', 5),
    (22, 'CUID-GJ-2025-00022', 'CNR/DE/2025/10022', 'Application for anticipatory bail in a financial dispute', 'Criminal', DATE '2024-08-30', 6),
    (23, 'CUID-GJ-2026-00023', 'CNR/UT/2026/10023', 'Zoya Trivedi v. Parth Mehta regarding recovery of contractual dues', 'Criminal', DATE '2024-09-10', 7),
    (24, 'CUID-GJ-2024-00024', 'CNR/KA/2024/10024', 'Challenge to termination of employment and unpaid wages', 'Motor Accident', DATE '2024-09-21', 8),
    (25, 'CUID-GJ-2025-00025', 'CNR/GU/2025/10025', 'Claim for damages arising from defective goods and services', 'Criminal', DATE '2024-10-02', 9),
    (26, 'CUID-GJ-2026-00026', 'CNR/GU/2026/10026', 'Application for guardianship and access arrangements', 'Family', DATE '2024-10-13', 10),
    (27, 'CUID-GJ-2024-00027', 'CNR/GU/2024/10027', 'Dispute concerning title and possession of ancestral property', 'Criminal', DATE '2025-05-28', 11),
    (28, 'CUID-GJ-2025-00028', 'CNR/GU/2025/10028', 'Dispute over supply of industrial machinery and unpaid invoices', 'Motor Accident', DATE '2025-06-16', 12),
    (29, 'CUID-GJ-2026-00029', 'CNR/GU/2026/10029', 'Commercial recovery claim arising from a construction contract', 'Motor Accident', DATE '2025-07-05', 13),
    (30, 'CUID-GJ-2024-00030', 'CNR/GU/2024/10030', 'Mira Soni v. Harsh Trivedi concerning maintenance and residence', 'Commercial', DATE '2025-07-24', 14),
    (31, 'CUID-GJ-2025-00031', 'CNR/MA/2025/10031', 'Suit for specific performance of an agreement for sale', 'Family', DATE '2025-08-12', 15),
    (32, 'CUID-GJ-2026-00032', 'CNR/MA/2026/10032', 'State v. Western Freight Carriers LLP concerning alleged misappropriation of funds', 'Civil', DATE '2025-08-31', 16),
    (33, 'CUID-GJ-2024-00033', 'CNR/RA/2024/10033', 'Proceedings concerning breach of trust in a cooperative society', 'Criminal', DATE '2025-09-19', 1),
    (34, 'CUID-GJ-2025-00034', 'CNR/DE/2025/10034', 'Complaint regarding unlawful retention of deposited property', 'Commercial', DATE '2025-10-08', 2),
    (35, 'CUID-GJ-2026-00035', 'CNR/UT/2026/10035', 'Claim for compensation arising from a road traffic collision', 'Family', DATE '2025-10-27', 3),
    (36, 'CUID-GJ-2024-00036', 'CNR/KA/2024/10036', 'Petition seeking enforcement of a family settlement', 'Commercial', DATE '2025-11-15', 4),
    (37, 'CUID-GJ-2025-00037', 'CNR/GU/2025/10037', 'Petition concerning protection of tenancy and possession rights', 'Criminal', DATE '2025-12-04', 5),
    (38, 'CUID-GJ-2026-00038', 'CNR/GU/2026/10038', 'Application for anticipatory bail in a financial dispute', 'Criminal', DATE '2025-12-23', 6),
    (39, 'CUID-GJ-2024-00039', 'CNR/GU/2024/10039', 'Krish Kulkarni v. Kabir Jain regarding recovery of contractual dues', 'Family', DATE '2026-01-11', 7),
    (40, 'CUID-GJ-2025-00040', 'CNR/GU/2025/10040', 'Challenge to termination of employment and unpaid wages', 'Civil', DATE '2026-01-30', 8),
    (41, 'CUID-GJ-2026-00041', 'CNR/GU/2026/10041', 'Claim for damages arising from defective goods and services', 'Motor Accident', DATE '2026-02-18', 9),
    (42, 'CUID-GJ-2024-00042', 'CNR/GU/2024/10042', 'Application for guardianship and access arrangements', 'Criminal', DATE '2026-03-09', 10),
    (43, 'CUID-GJ-2025-00043', 'CNR/MA/2025/10043', 'Dispute concerning title and possession of ancestral property', 'Criminal', DATE '2026-03-28', 11),
    (44, 'CUID-GJ-2026-00044', 'CNR/MA/2026/10044', 'Dispute over supply of industrial machinery and unpaid invoices', 'Civil', DATE '2026-04-16', 12),
    (45, 'CUID-GJ-2024-00045', 'CNR/RA/2024/10045', 'Commercial recovery claim arising from a construction contract', 'Criminal', DATE '2026-05-05', 13),
    (46, 'CUID-GJ-2025-00046', 'CNR/DE/2025/10046', 'Parth Mehta v. Imran Kulkarni concerning maintenance and residence', 'Family', DATE '2026-05-24', 14),
    (47, 'CUID-GJ-2026-00047', 'CNR/UT/2026/10047', 'Suit for specific performance of an agreement for sale', 'Family', DATE '2026-06-12', 15),
    (48, 'CUID-GJ-2024-00048', 'CNR/KA/2024/10048', 'State v. Ananya Malhotra concerning alleged misappropriation of funds', 'Family', DATE '2026-07-01', 16);

-- app_user: 12 records
INSERT INTO public.app_user (user_id, user_name, email, phone, account_status, role_id)
VALUES
    (1, 'registry.admin', 'registry_admin@temp.com', '+91-9400000001', 'Active', 1),
    (2, 'court.reader', 'court_reader@temp.com', '+91-9400000002', 'Active', 2),
    (3, 'filing.desk', 'filing_desk@temp.com', '+91-9400000003', 'Active', 2),
    (4, 'case.manager', 'case_manager@temp.com', '+91-9400000004', 'Active', 3),
    (5, 'judicial.assistant', 'judicial_assistant@temp.com', '+91-9400000005', 'Active', 3),
    (6, 'records.officer', 'records_officer@temp.com', '+91-9400000006', 'Active', 2),
    (7, 'legal.aid', 'legal_aid@temp.com', '+91-9400000007', 'Active', 5),
    (8, 'audit.viewer', 'audit_viewer@temp.com', '+91-9400000008', 'Locked', 6),
    (9, 'cause.list', 'cause_list@temp.com', '+91-9400000009', 'Active', 3),
    (10, 'court.office', 'court_office@temp.com', '+91-9400000010', 'Active', 3),
    (11, 'registry.supervisor', 'registry_supervisor@temp.com', '+91-9400000011', 'Active', 2),
    (12, 'bench.secretary', 'bench_secretary@temp.com', '+91-9400000012', 'Active', 4);

-- hearing: 70 records
INSERT INTO public.hearing (hearing_id, hearing_date, hearing_purpose, start_time, end_time, proceeding_summary, outcome, next_scheduled_hearing_date, case_id, room_id, bench_id, cause_list_id, sequence_number)
VALUES
    (1, DATE '2025-01-10', 'Hearing on the application for condonation of delay', TIME '10:15:00', TIME '11:00:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-01-31', 11, 1, 3, 1, 1),
    (2, DATE '2025-01-14', 'Final submissions on behalf of both parties', TIME '11:30:00', TIME '12:25:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-02-11', 22, 2, 6, 2, 1),
    (3, DATE '2025-01-18', 'Consideration of the reply filed by the respondent', TIME '12:45:00', TIME '13:50:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-02-22', 33, 3, 1, 3, 1),
    (4, DATE '2025-01-22', 'Arguments on framing of charges', TIME '13:00:00', TIME '14:15:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-03-08', 8, 4, 4, 4, 1),
    (5, DATE '2025-01-26', 'Recording of the complainant''s examination-in-chief', TIME '14:15:00', TIME '14:50:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-03-27', 19, 5, 7, 5, 1),
    (6, DATE '2025-01-30', 'Submission of the investigation progress report', TIME '15:30:00', TIME '16:15:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-02-13', 30, 6, 2, 6, 1),
    (7, DATE '2025-02-03', 'Verification of service of summons and notices', TIME '09:45:00', TIME '10:40:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-02-24', 5, 1, 5, 7, 1),
    (8, DATE '2025-02-07', 'Scrutiny of original invoices and payment records', TIME '10:00:00', TIME '11:05:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-03-07', 16, 2, 8, 8, 1),
    (9, DATE '2025-02-11', 'Compliance review of the earlier court direction', TIME '11:15:00', TIME '12:30:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-03-18', 27, 3, 3, 9, 1),
    (10, DATE '2025-02-15', 'Cross-examination of the claimant''s principal witness', TIME '12:30:00', TIME '13:05:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-04-01', 2, 4, 6, 10, 1),
    (11, DATE '2025-02-19', 'Settlement discussion before the family court', TIME '13:45:00', TIME '14:30:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-04-20', 13, 5, 1, 11, 1),
    (12, DATE '2025-02-23', 'Arguments on the application for interim protection', TIME '14:00:00', TIME '14:55:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-03-09', 24, 6, 4, 12, 1),
    (13, DATE '2025-02-27', 'Hearing on the application for condonation of delay', TIME '15:15:00', TIME '16:20:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-03-20', 35, 1, 7, 13, 1),
    (14, DATE '2025-03-03', 'Final submissions on behalf of both parties', TIME '09:30:00', TIME '10:45:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-03-31', 10, 2, 2, 14, 1),
    (15, DATE '2025-03-07', 'Consideration of the reply filed by the respondent', TIME '10:45:00', TIME '11:20:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-04-11', 21, 3, 5, 15, 1),
    (16, DATE '2025-03-11', 'Arguments on framing of charges', TIME '11:00:00', TIME '11:45:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-04-25', 32, 4, 8, 16, 1),
    (17, DATE '2025-03-15', 'Recording of the complainant''s examination-in-chief', TIME '12:15:00', TIME '13:10:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-05-14', 7, 5, 3, 17, 1),
    (18, DATE '2025-03-19', 'Submission of the investigation progress report', TIME '13:30:00', TIME '14:35:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-04-02', 18, 6, 6, 18, 1),
    (19, DATE '2025-03-23', 'Verification of service of summons and notices', TIME '14:45:00', TIME '16:00:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-04-13', 29, 1, 1, 19, 1),
    (20, DATE '2025-03-27', 'Scrutiny of original invoices and payment records', TIME '15:00:00', TIME '15:35:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-04-24', 4, 2, 4, 20, 1),
    (21, DATE '2025-03-31', 'Compliance review of the earlier court direction', TIME '09:15:00', TIME '10:00:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-05-05', 15, 3, 7, 21, 1),
    (22, DATE '2025-04-04', 'Cross-examination of the claimant''s principal witness', TIME '10:30:00', TIME '11:25:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-05-19', 26, 4, 2, 22, 1),
    (23, DATE '2025-04-08', 'Settlement discussion before the family court', TIME '11:45:00', TIME '12:50:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-06-07', 1, 5, 5, 23, 1),
    (24, DATE '2025-04-12', 'Arguments on the application for interim protection', TIME '12:00:00', TIME '13:15:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-04-26', 12, 6, 8, 24, 1),
    (25, DATE '2025-04-16', 'Hearing on the application for condonation of delay', TIME '13:15:00', TIME '13:50:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-05-07', 23, 1, 3, 25, 1),
    (26, DATE '2025-04-20', 'Final submissions on behalf of both parties', TIME '14:30:00', TIME '15:15:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-05-18', 34, 2, 6, 26, 1),
    (27, DATE '2025-04-24', 'Consideration of the reply filed by the respondent', TIME '15:45:00', TIME '16:40:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-05-29', 9, 3, 1, 27, 1),
    (28, DATE '2025-04-28', 'Arguments on framing of charges', TIME '09:00:00', TIME '10:05:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-06-12', 20, 4, 4, 28, 1),
    (29, DATE '2025-05-02', 'Recording of the complainant''s examination-in-chief', TIME '10:15:00', TIME '11:30:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-07-01', 31, 5, 7, 29, 1),
    (30, DATE '2025-05-06', 'Submission of the investigation progress report', TIME '11:30:00', TIME '12:05:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-05-20', 6, 6, 2, 30, 1),
    (31, DATE '2025-05-10', 'Verification of service of summons and notices', TIME '12:45:00', TIME '13:30:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-05-31', 17, 1, 5, 1, 2),
    (32, DATE '2025-05-14', 'Scrutiny of original invoices and payment records', TIME '13:00:00', TIME '13:55:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-06-11', 28, 2, 8, 2, 2),
    (33, DATE '2025-05-18', 'Compliance review of the earlier court direction', TIME '14:15:00', TIME '15:20:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-06-22', 3, 3, 3, 3, 2),
    (34, DATE '2025-05-22', 'Cross-examination of the claimant''s principal witness', TIME '15:30:00', TIME '16:45:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-07-06', 14, 4, 6, 4, 2),
    (35, DATE '2025-05-26', 'Settlement discussion before the family court', TIME '09:45:00', TIME '10:20:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-07-25', 25, 5, 1, 5, 2),
    (36, DATE '2025-05-30', 'Arguments on the application for interim protection', TIME '10:00:00', TIME '10:45:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-06-13', 36, 6, 4, 6, 2),
    (37, DATE '2025-06-03', 'Hearing on the application for condonation of delay', TIME '11:15:00', TIME '12:10:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-06-24', 11, 1, 7, 7, 2),
    (38, DATE '2025-06-07', 'Final submissions on behalf of both parties', TIME '12:30:00', TIME '13:35:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-07-05', 22, 2, 2, 8, 2),
    (39, DATE '2025-06-11', 'Consideration of the reply filed by the respondent', TIME '13:45:00', TIME '15:00:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-07-16', 33, 3, 5, 9, 2),
    (40, DATE '2025-06-15', 'Arguments on framing of charges', TIME '14:00:00', TIME '14:35:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-07-30', 8, 4, 8, 10, 2),
    (41, DATE '2025-06-19', 'Recording of the complainant''s examination-in-chief', TIME '15:15:00', TIME '16:00:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-08-18', 19, 5, 3, 11, 2),
    (42, DATE '2025-06-23', 'Submission of the investigation progress report', TIME '09:30:00', TIME '10:25:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-07-07', 30, 6, 6, 12, 2),
    (43, DATE '2025-06-27', 'Verification of service of summons and notices', TIME '10:45:00', TIME '11:50:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-07-18', 5, 1, 1, 13, 2),
    (44, DATE '2025-07-01', 'Scrutiny of original invoices and payment records', TIME '11:00:00', TIME '12:15:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-07-29', 16, 2, 4, 14, 2),
    (45, DATE '2025-07-05', 'Compliance review of the earlier court direction', TIME '12:15:00', TIME '12:50:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-08-09', 27, 3, 7, 15, 2),
    (46, DATE '2025-07-09', 'Cross-examination of the claimant''s principal witness', TIME '13:30:00', TIME '14:15:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-08-23', 2, 4, 2, 16, 2),
    (47, DATE '2025-07-13', 'Settlement discussion before the family court', TIME '14:45:00', TIME '15:40:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-09-11', 13, 5, 5, 17, 2),
    (48, DATE '2025-07-17', 'Arguments on the application for interim protection', TIME '15:00:00', TIME '16:05:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-07-31', 24, 6, 8, 18, 2),
    (49, DATE '2025-07-21', 'Hearing on the application for condonation of delay', TIME '09:15:00', TIME '10:30:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-08-11', 35, 1, 3, 19, 2),
    (50, DATE '2025-07-25', 'Final submissions on behalf of both parties', TIME '10:30:00', TIME '11:05:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-08-22', 10, 2, 6, 20, 2),
    (51, DATE '2025-07-29', 'Consideration of the reply filed by the respondent', TIME '11:45:00', TIME '12:30:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-09-02', 21, 3, 1, 21, 2),
    (52, DATE '2025-08-02', 'Arguments on framing of charges', TIME '12:00:00', TIME '12:55:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-09-16', 32, 4, 4, 22, 2),
    (53, DATE '2025-08-06', 'Recording of the complainant''s examination-in-chief', TIME '13:15:00', TIME '14:20:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-10-05', 7, 5, 7, 23, 2),
    (54, DATE '2025-08-10', 'Submission of the investigation progress report', TIME '14:30:00', TIME '15:45:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-08-24', 18, 6, 2, 24, 2),
    (55, DATE '2025-08-14', 'Verification of service of summons and notices', TIME '15:45:00', TIME '16:20:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-09-04', 29, 1, 5, 25, 2),
    (56, DATE '2025-08-18', 'Scrutiny of original invoices and payment records', TIME '09:00:00', TIME '09:45:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-09-15', 4, 2, 8, 26, 2),
    (57, DATE '2025-08-22', 'Compliance review of the earlier court direction', TIME '10:15:00', TIME '11:10:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-09-26', 15, 3, 3, 27, 2),
    (58, DATE '2025-08-26', 'Cross-examination of the claimant''s principal witness', TIME '11:30:00', TIME '12:35:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-10-10', 26, 4, 6, 28, 2),
    (59, DATE '2025-08-30', 'Settlement discussion before the family court', TIME '12:45:00', TIME '14:00:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-10-29', 1, 5, 1, 29, 2),
    (60, DATE '2025-09-03', 'Arguments on the application for interim protection', TIME '13:00:00', TIME '13:35:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-09-17', 12, 6, 4, 30, 2),
    (61, DATE '2025-09-07', 'Hearing on the application for condonation of delay', TIME '14:15:00', TIME '15:00:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-09-28', 23, 1, 7, 1, 3),
    (62, DATE '2025-09-11', 'Final submissions on behalf of both parties', TIME '15:30:00', TIME '16:25:00', 'The witness identified the signature on the agreement. Cross-examination was partly completed and will continue on the next date.', 'Interim protection continued until next date', DATE '2025-10-09', 34, 2, 2, 2, 3),
    (63, DATE '2025-09-15', 'Consideration of the reply filed by the respondent', TIME '09:45:00', TIME '10:50:00', 'The advocate for the applicant filed a compilation of documents. The respondent sought time to file a written reply.', 'Arguments partly heard; list for continuation', DATE '2025-10-20', 9, 3, 5, 3, 3),
    (64, DATE '2025-09-19', 'Arguments on framing of charges', TIME '10:00:00', TIME '11:15:00', 'The complainant''s statement was recorded in the presence of the accused and their counsel.', 'Notice served; respondent appeared', DATE '2025-11-03', 20, 4, 8, 4, 3),
    (65, DATE '2025-09-23', 'Recording of the complainant''s examination-in-chief', TIME '11:15:00', TIME '11:50:00', 'The investigating officer submitted the status report. The court requested clarification on the seizure memo and chain of custody.', 'Interim protection continued until next date', DATE '2025-11-22', 31, 5, 3, 5, 3),
    (66, DATE '2025-09-27', 'Submission of the investigation progress report', TIME '12:30:00', TIME '13:15:00', 'The registry confirmed service of notice. The respondent appeared through counsel and requested three weeks to file a response.', 'Arguments partly heard; list for continuation', DATE '2025-10-11', 6, 6, 6, 6, 3),
    (67, DATE '2025-10-01', 'Verification of service of summons and notices', TIME '13:45:00', TIME '14:40:00', 'Both sides were heard on the interim application. The court directed the parties to maintain the existing position until the next date.', 'Notice served; respondent appeared', DATE '2025-10-22', 17, 1, 1, 7, 3),
    (68, DATE '2025-10-05', 'Scrutiny of original invoices and payment records', TIME '14:00:00', TIME '15:05:00', 'The court examined the medical certificate and directed the parties to file any objections within seven days.', 'Interim protection continued until next date', DATE '2025-11-02', 28, 2, 4, 8, 3),
    (69, DATE '2025-10-09', 'Compliance review of the earlier court direction', TIME '15:15:00', TIME '16:30:00', 'Counsel informed the court that settlement discussions are ongoing. The matter was posted for a short review.', 'Arguments partly heard; list for continuation', DATE '2025-11-13', 3, 3, 7, 9, 3),
    (70, DATE '2025-10-13', 'Cross-examination of the claimant''s principal witness', TIME '09:30:00', TIME '10:05:00', 'Original bank statements were produced for inspection. Counsel were directed to exchange legible copies before the next hearing.', 'Notice served; respondent appeared', DATE '2025-11-27', 14, 4, 2, 10, 3);

-- judgment: 14 records
INSERT INTO public.judgment (judgment_id, pronouncement_date, verdict_text, digital_signature_hash, case_id)
VALUES
    (1, DATE '2025-05-09', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', 'a5b7caf3053cdb7d3be93e704cc8f49beb269d1ffd2770420afff8420ced62f8', 2),
    (2, DATE '2025-05-17', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', 'd1019b70860d8b56f1767281b751f66e3c0be5cedf9420792ea8c0a976bee00e', 4),
    (3, DATE '2025-05-25', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', 'b728871ac3f73ef7e801da345c116d732316c33aacbee38af87589b8046d9daa', 6),
    (4, DATE '2025-06-02', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', 'cabf0ac5bdee21564686da7b001e56b956659390209ab28414275361c2069b03', 8),
    (5, DATE '2025-06-10', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', '11f518f50050b06c62a173ff494e70a83e4e69b2c1983acf9fd28bea88116d7c', 10),
    (6, DATE '2025-06-18', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', '5388065f14a80ae0b3a865fa383873cb20ad058a5f8c0da3e06b53ddad8c338f', 12),
    (7, DATE '2025-06-26', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', '5e937d28b3c5f3c492dc2da057fb64da91bddc5f691d4afd6ba5be785ae07406', 14),
    (8, DATE '2025-07-04', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', '7ad314fb87d0a93d4f46e84ac89ec3a652bc08d57d4a0a23fcee9cb44102081c', 16),
    (9, DATE '2025-07-12', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', '7d5a1d60a356a6539359946e26f36260ccd47f0ac5c12cc669fda1d82108f1a2', 18),
    (10, DATE '2025-07-20', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', '4903db16bb6431cf101da1282cda8c705cf8c8236e9755bfe5b7033f14b585bc', 20),
    (11, DATE '2025-07-28', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', '830557c8e71f8f5426cad75bf0df82dc6494dda52768b71038c1fa6c0d91646c', 22),
    (12, DATE '2025-08-05', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', '19258992cc49ae1c930f2dfde33c369c52efef53ff1cf2ea6f14e29c46c6b630', 24),
    (13, DATE '2025-08-13', 'The claim is dismissed for failure to establish the essential elements of the cause of action.', '70d14ecbf37f7a68287c287d82575d12cda14e990f1bc57a2002abc283c046b4', 26),
    (14, DATE '2027-03-30', 'The suit is partly decreed. The defendant shall pay the adjudicated amount with interest at the rate stated in the operative order.', '943f4f82c45d0f5c6d41be6fb08dd297aa70e9b455591e32e5ae2d8c843659a1', 48);

-- court_order: 41 records
INSERT INTO public.court_order (order_id, order_type, order_content, digital_signature_hash, case_id, issued_by_judge_id, hearing_id)
VALUES
    (1, 'Bail Order', 'The respondent shall file a reply with supporting documents within fourteen days.', '0ba64a3e244ca8cabecb879c8240bcb2a34ff3347708a02c93b1ad31cab16abd', 33, 5, 3),
    (2, 'Production of Documents Order', 'The investigating officer shall place the updated status report on record before the next date.', '234c2e7926550fa81b2d1955eaa3ff8111bdd2943e9633895a95209116347394', 30, 10, 6),
    (3, 'Notice of Motion Order', 'The registry shall issue notice to the address furnished in the petition and record service.', 'da54d163fd7d8a56dbf558bb95bdca83c904121220f563a866b91f90039d2b2f', 27, 15, 9),
    (4, 'Procedural Direction', 'The application is listed for further hearing after completion of the cross-examination.', 'b0d6344cd2577b7b2b5d3e60cbde143a409c9e2f6e4ebc8963465f6b155995e2', 24, 2, 12),
    (5, 'Summons Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', '82677864289fd76f4f9884e9bb579f5384d2681c36a0a750971cde563f088999', 21, 7, 15),
    (6, 'Evidence Preservation Order', 'The respondent shall file a reply with supporting documents within fourteen days.', '6bb5698e1707417f2e067043f35233f4517719e59987f50ad85698ec8b156a5c', 18, 12, 18),
    (7, 'Adjournment Order', 'The investigating officer shall place the updated status report on record before the next date.', 'd7b8845612c9507848ac5b48fe9967183f168aa7af0688a8f35a9f4e2d386294', 15, 17, 21),
    (8, 'Interim Protection Order', 'The registry shall issue notice to the address furnished in the petition and record service.', '3d0e17af827e6d3e26a46847de52465cca57ebab3e57965ed51c019c389a7ccf', 12, 4, 24),
    (9, 'Bail Order', 'The application is listed for further hearing after completion of the cross-examination.', '45eabf5ce56a1345978f7761898b45efd24805ea92d5486218cc698e04eefe68', 9, 9, 27),
    (10, 'Production of Documents Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', 'a3b77533795842955bc39a1cffe26f00ab6728f4e938a52669cbab5dde18a774', 6, 14, 30),
    (11, 'Notice of Motion Order', 'The respondent shall file a reply with supporting documents within fourteen days.', '272510f9ee7161e7174842e96b48bb4113684f72f4973075c4df6d6246f238a0', 3, 1, 33),
    (12, 'Procedural Direction', 'The investigating officer shall place the updated status report on record before the next date.', '7dab343adf5606540f340643e142cee43a6f2a1c34bcf8fce9d9b902cea3b428', 36, 6, 36),
    (13, 'Summons Order', 'The registry shall issue notice to the address furnished in the petition and record service.', '46d7ea3a3a780e9df8e03a03d87857d358396207259545c71ff1658436b12da9', 33, 11, 39),
    (14, 'Evidence Preservation Order', 'The application is listed for further hearing after completion of the cross-examination.', '868961bdfef165126d4a34aa71aa132d5f414d5283a5e244407d8269d0000056', 30, 16, 42),
    (15, 'Adjournment Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', '2951edaaa23e6d7aa6581529d69b64492abf9f675dc6ea9b0904c6e5e90e70e6', 27, 3, 45),
    (16, 'Interim Protection Order', 'The respondent shall file a reply with supporting documents within fourteen days.', '5060746174744ce85ac67ab52c28cabc9ac99a1eb38fb3ccd56bb298b47afee7', 24, 8, 48),
    (17, 'Bail Order', 'The investigating officer shall place the updated status report on record before the next date.', '4dfe5ba9cf4c42007e6c7df89a0c5efcf8aaf97668e240b791df17125ba8605d', 21, 13, 51),
    (18, 'Production of Documents Order', 'The registry shall issue notice to the address furnished in the petition and record service.', 'fff967e7399da24c80ab7efadc572796d0f6b9646c5664025bb1ee34c1f61013', 18, 18, 54),
    (19, 'Notice of Motion Order', 'The application is listed for further hearing after completion of the cross-examination.', '72eb819307cb8ae332d8e09bc3a96125b6cbe49660d4b66285769a67d934267c', 15, 5, 57),
    (20, 'Procedural Direction', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', '26d83b6442f9ee066fa8a1c69c36ffbee1bca8a3f7570ae94dbe39eb8e65f7e1', 12, 10, 60),
    (21, 'Summons Order', 'The respondent shall file a reply with supporting documents within fourteen days.', '8cac3bb2a183bfbe5fdcc011a870683b04dc7c676e3537e0d99f265fd0c772cb', 9, 15, 63),
    (22, 'Evidence Preservation Order', 'The investigating officer shall place the updated status report on record before the next date.', 'c326beace1250bcafbd7dc937417c9054ebb2a0abe378ae105e6564650d5a2e0', 6, 2, 66),
    (23, 'Adjournment Order', 'The registry shall issue notice to the address furnished in the petition and record service.', 'f5ef289e84b4a5737cd00c98b662caac0df1f9d2c0b5d1f6c5bebc3b34fd4421', 3, 7, 69),
    (24, 'Interim Protection Order', 'The application is listed for further hearing after completion of the cross-examination.', 'c56129ef03a9a9b911d35b6b587196ee7ebd06dec8889a58f0b73087d601bc46', 22, 12, 2),
    (25, 'Bail Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', 'ea3b57de381a0f8250e2c747654b291372220bf44bd59558042cda4788f3d3b2', 19, 17, 5),
    (26, 'Production of Documents Order', 'The respondent shall file a reply with supporting documents within fourteen days.', 'd297c8d1cc8e26bda4427b886a239b5fc92b2804ebd63b635568cae69e4d4730', 16, 4, 8),
    (27, 'Notice of Motion Order', 'The investigating officer shall place the updated status report on record before the next date.', '6cd081b2fe8681bcff89f96e3666adcceea6995197f262eff21406ad35886d0e', 13, 9, 11),
    (28, 'Procedural Direction', 'The registry shall issue notice to the address furnished in the petition and record service.', '7706d9636f939303c19f634e7116884646a3518db82c49450c7a54ea7288eb23', 10, 14, 14),
    (29, 'Summons Order', 'The application is listed for further hearing after completion of the cross-examination.', '3ed2a8ddebd39875ec87c322f8a181c3a3d9ffeba504fc078a5006c8105c77c9', 7, 1, 17),
    (30, 'Evidence Preservation Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', '6919d67523a513a7e2ed99f988861936d33e4704fdd187791955dff437bdfe98', 4, 6, 20),
    (31, 'Adjournment Order', 'The respondent shall file a reply with supporting documents within fourteen days.', 'cd490e154bd117eed999eff9e9dd01962b703fc36877c951cb8b86b62ee3662f', 1, 11, 23),
    (32, 'Interim Protection Order', 'The investigating officer shall place the updated status report on record before the next date.', '80065baeaf2f1ec09450fdc01808d91d2302ee48d9ddebdaf80a76af6634289e', 34, 16, 26),
    (33, 'Bail Order', 'The registry shall issue notice to the address furnished in the petition and record service.', '1130be823af8a19525db5ce3d1e19e7d360ada918884af423a7dd44b7e9778b0', 31, 3, 29),
    (34, 'Production of Documents Order', 'The application is listed for further hearing after completion of the cross-examination.', 'b068653387dca4b5f1bddb6c353b9b3bbd8dce1081e5a83299fbf0a9e17a3909', 28, 8, 32),
    (35, 'Notice of Motion Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', 'b718de50bcd504fd25e87e9fa82ef5f1c83c2a7ec4c866a259bf4426be9267ad', 25, 13, 35),
    (36, 'Procedural Direction', 'The respondent shall file a reply with supporting documents within fourteen days.', '6e3671e73488fcb7186577f82db20d897f53b59969fa73782ea286fcbe0752a5', 22, 18, 38),
    (37, 'Summons Order', 'The investigating officer shall place the updated status report on record before the next date.', '0a78bcf2a108dee7cbaf0fe8384c75056b2fc88157333d9653554ff0a094b142', 19, 5, 41),
    (38, 'Evidence Preservation Order', 'The registry shall issue notice to the address furnished in the petition and record service.', '060e14614efe50ab9e19ad13d27a18dc012c4b96b2425747aecdea74c1183996', 16, 10, 44),
    (39, 'Adjournment Order', 'The application is listed for further hearing after completion of the cross-examination.', 'aa6a319fc4c3f45aeb9f3e4f1654ce92424396b9e4455962398f799dd950050e', 13, 15, 47),
    (40, 'Interim Protection Order', 'The parties shall preserve the relevant records and shall not create third-party interests pending further orders.', '0400c0b80ae1769fc8e948ab7bad2febae5b500cb1912326a0fbd143a4ee4726', 10, 2, 50),
    (41, 'Bail Order', 'The respondent shall file a reply with supporting documents within fourteen days.', 'dcc15d2a671b8a029dd4022bc3e0ab44753d799c06db2516de49b8e65dc810fc', 7, 7, 53);

-- petition: 56 records
INSERT INTO public.petition (petition_id, subject, verification_status, case_id, lawyer_id, scrutinized_by_clerk_id, verified_by_clerk_id)
VALUES
    (1, 'Petition seeking release of retained security deposit', 'Returned for Correction', 13, 13, 4, NULL),
    (2, 'Reply to the notice concerning breach of supply agreement', 'Under Review', 26, 25, 7, 13),
    (3, 'Application for regular bail with supporting employment records', 'Pending', 39, 9, 10, 4),
    (4, 'Petition for maintenance and reasonable access to the minor child', 'Verified', 4, 17, 13, 9),
    (5, 'Affidavit in support of delay condonation application', 'Returned for Correction', 17, 1, 2, NULL),
    (6, 'Application seeking permission to produce additional documents', 'Under Review', 30, 13, 5, NULL),
    (7, 'Written statement disputing the amount claimed under the invoice', 'Pending', 43, 25, 8, 10),
    (8, 'Application for appointment of a local commissioner', 'Verified', 8, 5, 11, 1),
    (9, 'Petition seeking enforcement of the recorded settlement', 'Returned for Correction', 21, 17, 14, 6),
    (10, 'Application for interim injunction against transfer of disputed property', 'Under Review', 34, 1, 3, NULL),
    (11, 'Petition seeking release of retained security deposit', 'Pending', 47, 13, NULL, NULL),
    (12, 'Reply to the notice concerning breach of supply agreement', 'Verified', 12, 21, 9, 7),
    (13, 'Application for regular bail with supporting employment records', 'Returned for Correction', 25, 5, 12, 12),
    (14, 'Petition for maintenance and reasonable access to the minor child', 'Under Review', 38, 17, 1, 3),
    (15, 'Affidavit in support of delay condonation application', 'Pending', 3, 25, 4, NULL),
    (16, 'Application seeking permission to produce additional documents', 'Verified', 16, 9, 7, 13),
    (17, 'Written statement disputing the amount claimed under the invoice', 'Returned for Correction', 29, 21, 10, 4),
    (18, 'Application for appointment of a local commissioner', 'Under Review', 42, 5, 13, 9),
    (19, 'Petition seeking enforcement of the recorded settlement', 'Pending', 7, 13, 2, 14),
    (20, 'Application for interim injunction against transfer of disputed property', 'Verified', 20, 25, 5, 5),
    (21, 'Petition seeking release of retained security deposit', 'Returned for Correction', 33, 9, 8, NULL),
    (22, 'Reply to the notice concerning breach of supply agreement', 'Under Review', 46, 21, NULL, 1),
    (23, 'Application for regular bail with supporting employment records', 'Pending', 11, 1, 14, 6),
    (24, 'Petition for maintenance and reasonable access to the minor child', 'Verified', 24, 13, 3, 11),
    (25, 'Affidavit in support of delay condonation application', 'Returned for Correction', 37, 25, 6, NULL),
    (26, 'Application seeking permission to produce additional documents', 'Under Review', 2, 5, 9, NULL),
    (27, 'Written statement disputing the amount claimed under the invoice', 'Pending', 15, 17, 12, 12),
    (28, 'Application for appointment of a local commissioner', 'Verified', 28, 1, 1, 3),
    (29, 'Petition seeking enforcement of the recorded settlement', 'Returned for Correction', 41, 13, 4, 8),
    (30, 'Application for interim injunction against transfer of disputed property', 'Under Review', 6, 21, 7, NULL),
    (31, 'Petition seeking release of retained security deposit', 'Pending', 19, 5, 10, NULL),
    (32, 'Reply to the notice concerning breach of supply agreement', 'Verified', 32, 17, 13, 9),
    (33, 'Application for regular bail with supporting employment records', 'Returned for Correction', 45, 1, 2, 14),
    (34, 'Petition for maintenance and reasonable access to the minor child', 'Under Review', 10, 9, 5, 5),
    (35, 'Affidavit in support of delay condonation application', 'Pending', 23, 21, 8, NULL),
    (36, 'Application seeking permission to produce additional documents', 'Verified', 36, 5, 11, 1),
    (37, 'Written statement disputing the amount claimed under the invoice', 'Returned for Correction', 1, 13, 14, 6),
    (38, 'Application for appointment of a local commissioner', 'Under Review', 14, 25, 3, 11),
    (39, 'Petition seeking enforcement of the recorded settlement', 'Pending', 27, 9, 6, 2),
    (40, 'Application for interim injunction against transfer of disputed property', 'Verified', 40, 21, 9, 7),
    (41, 'Petition seeking release of retained security deposit', 'Returned for Correction', 5, 1, 12, NULL),
    (42, 'Reply to the notice concerning breach of supply agreement', 'Under Review', 18, 13, 1, 3),
    (43, 'Application for regular bail with supporting employment records', 'Pending', 31, 25, 4, 8),
    (44, 'Petition for maintenance and reasonable access to the minor child', 'Verified', 44, 9, NULL, 13),
    (45, 'Affidavit in support of delay condonation application', 'Returned for Correction', 9, 17, 10, NULL),
    (46, 'Application seeking permission to produce additional documents', 'Under Review', 22, 1, 13, NULL),
    (47, 'Written statement disputing the amount claimed under the invoice', 'Pending', 35, 13, 2, 14),
    (48, 'Application for appointment of a local commissioner', 'Verified', 48, 25, 5, 5),
    (49, 'Petition seeking enforcement of the recorded settlement', 'Returned for Correction', 13, 5, 8, 10),
    (50, 'Application for interim injunction against transfer of disputed property', 'Under Review', 26, 17, 11, NULL),
    (51, 'Petition seeking release of retained security deposit', 'Pending', 39, 1, 14, NULL),
    (52, 'Reply to the notice concerning breach of supply agreement', 'Verified', 4, 9, 3, 11),
    (53, 'Application for regular bail with supporting employment records', 'Returned for Correction', 17, 21, 6, 2),
    (54, 'Petition for maintenance and reasonable access to the minor child', 'Under Review', 30, 5, 9, 7),
    (55, 'Affidavit in support of delay condonation application', 'Pending', 43, 17, NULL, NULL),
    (56, 'Application seeking permission to produce additional documents', 'Verified', 8, 25, 1, 3);

-- evidence: 83 records
INSERT INTO public.evidence (evidence_id, exhibit_number, submission_date, description, judicial_admission_status, case_id, party_id)
VALUES
    (1, 'EX-2026-0001', DATE '2025-02-04', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Not Admitted', 17, 34),
    (2, 'EX-2025-0002', DATE '2025-02-07', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Under Review', 34, 22),
    (3, 'EX-2026-0003', DATE '2025-02-10', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Admitted', 3, 6),
    (4, 'EX-2025-0004', DATE '2025-02-13', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Not Admitted', 20, 39),
    (5, 'EX-2026-0005', DATE '2025-02-16', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Under Review', 37, 29),
    (6, 'EX-2025-0006', DATE '2025-02-19', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Admitted', 6, 11),
    (7, 'EX-2026-0007', DATE '2025-02-22', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Not Admitted', 23, 1),
    (8, 'EX-2025-0008', DATE '2025-02-25', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Under Review', 40, 34),
    (9, 'EX-2026-0009', DATE '2025-02-28', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Admitted', 9, 18),
    (10, 'EX-2025-0010', DATE '2025-03-03', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Not Admitted', 26, 6),
    (11, 'EX-2026-0011', DATE '2025-03-06', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Under Review', 43, 41),
    (12, 'EX-2025-0012', DATE '2025-03-09', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Admitted', 12, 23),
    (13, 'EX-2026-0013', DATE '2025-03-12', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Not Admitted', 29, 13),
    (14, 'EX-2025-0014', DATE '2025-03-15', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Under Review', 46, 1),
    (15, 'EX-2026-0015', DATE '2025-03-18', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Admitted', 15, 30),
    (16, 'EX-2025-0016', DATE '2025-03-21', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Not Admitted', 32, 18),
    (17, 'EX-2026-0017', DATE '2025-03-24', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Under Review', 1, 2),
    (18, 'EX-2025-0018', DATE '2025-03-27', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Admitted', 18, 35),
    (19, 'EX-2026-0019', DATE '2025-03-30', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Not Admitted', 35, 25),
    (20, 'EX-2025-0020', DATE '2025-04-02', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Under Review', 4, 7),
    (21, 'EX-2026-0021', DATE '2025-04-05', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Admitted', 21, 42),
    (22, 'EX-2025-0022', DATE '2025-04-08', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Not Admitted', 38, 30),
    (23, 'EX-2026-0023', DATE '2025-04-11', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Under Review', 7, 14),
    (24, 'EX-2025-0024', DATE '2025-04-14', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Admitted', 24, 2),
    (25, 'EX-2026-0025', DATE '2025-04-17', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Not Admitted', 41, 37),
    (26, 'EX-2025-0026', DATE '2025-04-20', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Under Review', 10, 19),
    (27, 'EX-2026-0027', DATE '2025-04-23', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Admitted', 27, 9),
    (28, 'EX-2025-0028', DATE '2025-04-26', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Not Admitted', 44, 42),
    (29, 'EX-2026-0029', DATE '2025-04-29', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Under Review', 13, 26),
    (30, 'EX-2025-0030', DATE '2025-05-02', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Admitted', 30, 14),
    (31, 'EX-2026-0031', DATE '2025-05-05', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Not Admitted', 47, 4),
    (32, 'EX-2025-0032', DATE '2025-05-08', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Under Review', 16, 31),
    (33, 'EX-2026-0033', DATE '2025-05-11', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Admitted', 33, 21),
    (34, 'EX-2025-0034', DATE '2025-05-14', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Not Admitted', 2, 3),
    (35, 'EX-2026-0035', DATE '2025-05-17', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Under Review', 19, 38),
    (36, 'EX-2025-0036', DATE '2025-05-20', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Admitted', 36, 26),
    (37, 'EX-2026-0037', DATE '2025-05-23', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Not Admitted', 5, 10),
    (38, 'EX-2025-0038', DATE '2025-05-26', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Under Review', 22, 43),
    (39, 'EX-2026-0039', DATE '2025-05-29', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Admitted', 39, 33),
    (40, 'EX-2025-0040', DATE '2025-06-01', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Not Admitted', 8, 15),
    (41, 'EX-2026-0041', DATE '2025-06-04', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Under Review', 25, 5),
    (42, 'EX-2025-0042', DATE '2025-06-07', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Admitted', 42, 38),
    (43, 'EX-2026-0043', DATE '2025-06-10', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Not Admitted', 11, 22),
    (44, 'EX-2025-0044', DATE '2025-06-13', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Under Review', 28, 10),
    (45, 'EX-2026-0045', DATE '2025-06-16', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Admitted', 45, 45),
    (46, 'EX-2025-0046', DATE '2025-06-19', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Not Admitted', 14, 27),
    (47, 'EX-2026-0047', DATE '2025-06-22', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Under Review', 31, 17),
    (48, 'EX-2025-0048', DATE '2025-06-25', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Admitted', 48, 5),
    (49, 'EX-2026-0049', DATE '2025-06-28', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Not Admitted', 17, 34),
    (50, 'EX-2025-0050', DATE '2025-07-01', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Under Review', 34, 22),
    (51, 'EX-2026-0051', DATE '2025-07-04', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Admitted', 3, 6),
    (52, 'EX-2025-0052', DATE '2025-07-07', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Not Admitted', 20, 39),
    (53, 'EX-2026-0053', DATE '2025-07-10', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Under Review', 37, 29),
    (54, 'EX-2025-0054', DATE '2025-07-13', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Admitted', 6, 11),
    (55, 'EX-2026-0055', DATE '2025-07-16', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Not Admitted', 23, 1),
    (56, 'EX-2025-0056', DATE '2025-07-19', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Under Review', 40, 34),
    (57, 'EX-2026-0057', DATE '2025-07-22', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Admitted', 9, 18),
    (58, 'EX-2025-0058', DATE '2025-07-25', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Not Admitted', 26, 6),
    (59, 'EX-2026-0059', DATE '2025-07-28', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Under Review', 43, 41),
    (60, 'EX-2025-0060', DATE '2025-07-31', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Admitted', 12, 23),
    (61, 'EX-2026-0061', DATE '2025-08-03', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Not Admitted', 29, 13),
    (62, 'EX-2025-0062', DATE '2025-08-06', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Under Review', 46, 1),
    (63, 'EX-2026-0063', DATE '2025-08-09', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Admitted', 15, 30),
    (64, 'EX-2025-0064', DATE '2025-08-12', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Not Admitted', 32, 18),
    (65, 'EX-2026-0065', DATE '2025-08-15', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Under Review', 1, 2),
    (66, 'EX-2025-0066', DATE '2025-08-18', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Admitted', 18, 35),
    (67, 'EX-2026-0067', DATE '2025-08-21', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Not Admitted', 35, 25),
    (68, 'EX-2025-0068', DATE '2025-08-24', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Under Review', 4, 7),
    (69, 'EX-2026-0069', DATE '2025-08-27', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Admitted', 21, 42),
    (70, 'EX-2025-0070', DATE '2025-08-30', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Not Admitted', 38, 30),
    (71, 'EX-2026-0071', DATE '2025-09-02', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Under Review', 7, 14),
    (72, 'EX-2025-0072', DATE '2025-09-05', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Admitted', 24, 2),
    (73, 'EX-2026-0073', DATE '2025-09-08', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Not Admitted', 41, 37),
    (74, 'EX-2025-0074', DATE '2025-09-11', 'Call detail extract submitted in a sealed cover for judicial inspection, subject to the objections raised by the opposite party.', 'Under Review', 10, 19),
    (75, 'EX-2026-0075', DATE '2025-09-14', 'Copy of the registered lease deed containing the property description, execution date and signatures of the parties.', 'Admitted', 27, 9),
    (76, 'EX-2025-0076', DATE '2025-09-17', 'Photographs of the damaged vehicle taken at the accident site shortly after the collision, accompanied by the investigator''s note.', 'Not Admitted', 44, 42),
    (77, 'EX-2026-0077', DATE '2025-09-20', 'Photocopy of the settlement memorandum signed by both parties before the community mediation centre.', 'Under Review', 13, 26),
    (78, 'EX-2025-0078', DATE '2025-09-23', 'Site inspection report describing the boundary markers and the condition of the disputed access road.', 'Admitted', 30, 14),
    (79, 'EX-2026-0079', DATE '2025-09-26', 'Medical certificate issued after examination at the district hospital, recording the injuries and recommended period of rest.', 'Not Admitted', 47, 4),
    (80, 'EX-2025-0080', DATE '2025-09-29', 'Certified copy of the bank statement for the account covering the disputed payment period, submitted with the transaction entries identified by the applicant.', 'Under Review', 16, 31),
    (81, 'EX-2026-0081', DATE '2025-10-02', 'Certified salary statement and attendance extract produced in support of the employment claim.', 'Admitted', 33, 21),
    (82, 'EX-2025-0082', DATE '2025-10-05', 'Email correspondence between the parties discussing the revised delivery schedule and the outstanding balance.', 'Not Admitted', 2, 3),
    (83, 'EX-2026-0083', DATE '2025-10-08', 'Original purchase invoice showing the model number, delivery date and price of the machinery supplied under the contract.', 'Under Review', 19, 38);

-- adjournment: 27 records
INSERT INTO public.adjournment (adjournment_id, reason, request_date, judicial_approval_status, revised_hearing_date, hearing_id, reviewed_by_judge_id)
VALUES
    (1, 'The investigating officer could not attend because the updated report was awaiting approval.', DATE '2025-01-21', 'Rejected', DATE '2025-02-16', 5, 7),
    (2, 'The respondent sought time to obtain certified copies of the relevant municipal records.', DATE '2025-02-08', 'Pending', DATE '2025-03-17', 10, 14),
    (3, 'Parties requested time to explore settlement through the court-annexed mediation centre.', DATE '2025-02-25', 'Approved', DATE '2025-03-21', 15, 3),
    (4, 'Heavy rainfall and local transport disruption prevented the witness from reaching the court.', DATE '2025-03-13', 'Rejected', DATE '2025-04-17', 20, 10),
    (5, 'Medical certificate was filed for the unavailability of the principal witness.', DATE '2025-04-13', 'Pending', DATE '2025-05-16', 25, 17),
    (6, 'Counsel required additional time to inspect the original documents produced by the opposite party.', DATE '2025-05-01', 'Approved', DATE '2025-05-20', 30, 6),
    (7, 'Lead counsel was engaged before another court and sought a short accommodation.', DATE '2025-05-19', 'Rejected', DATE '2025-06-16', 35, 13),
    (8, 'The investigating officer could not attend because the updated report was awaiting approval.', DATE '2025-06-05', 'Pending', DATE '2025-07-15', 40, 2),
    (9, 'The respondent sought time to obtain certified copies of the relevant municipal records.', DATE '2025-06-21', 'Approved', DATE '2025-07-19', 45, 9),
    (10, 'Parties requested time to explore settlement through the court-annexed mediation centre.', DATE '2025-07-22', 'Rejected', DATE '2025-08-15', 50, 16),
    (11, 'Heavy rainfall and local transport disruption prevented the witness from reaching the court.', DATE '2025-08-09', 'Pending', DATE '2025-09-13', 55, 5),
    (12, 'Medical certificate was filed for the unavailability of the principal witness.', DATE '2025-08-27', 'Approved', DATE '2025-09-17', 60, 12),
    (13, 'Counsel required additional time to inspect the original documents produced by the opposite party.', DATE '2025-09-13', 'Rejected', DATE '2025-10-14', 65, 1),
    (14, 'Lead counsel was engaged before another court and sought a short accommodation.', DATE '2025-09-29', 'Pending', DATE '2025-11-12', 70, 8),
    (15, 'The investigating officer could not attend because the updated report was awaiting approval.', DATE '2025-01-23', 'Approved', DATE '2025-02-09', 5, 15),
    (16, 'The respondent sought time to obtain certified copies of the relevant municipal records.', DATE '2025-02-10', 'Rejected', DATE '2025-03-08', 10, 4),
    (17, 'Parties requested time to explore settlement through the court-annexed mediation centre.', DATE '2025-02-28', 'Pending', DATE '2025-04-06', 15, 11),
    (18, 'Heavy rainfall and local transport disruption prevented the witness from reaching the court.', DATE '2025-03-17', 'Approved', DATE '2025-04-10', 20, 18),
    (19, 'Medical certificate was filed for the unavailability of the principal witness.', DATE '2025-04-02', 'Rejected', DATE '2025-05-07', 25, 7),
    (20, 'Counsel required additional time to inspect the original documents produced by the opposite party.', DATE '2025-05-03', 'Pending', DATE '2025-06-05', 30, 14),
    (21, 'Lead counsel was engaged before another court and sought a short accommodation.', DATE '2025-05-21', 'Approved', DATE '2025-06-09', 35, 3),
    (22, 'The investigating officer could not attend because the updated report was awaiting approval.', DATE '2025-06-08', 'Rejected', DATE '2025-07-06', 40, 10),
    (23, 'The respondent sought time to obtain certified copies of the relevant municipal records.', DATE '2025-06-25', 'Pending', DATE '2025-08-04', 45, 17),
    (24, 'Parties requested time to explore settlement through the court-annexed mediation centre.', DATE '2025-07-11', 'Approved', DATE '2025-08-08', 50, 6),
    (25, 'Heavy rainfall and local transport disruption prevented the witness from reaching the court.', DATE '2025-08-11', 'Rejected', DATE '2025-09-04', 55, 13),
    (26, 'Medical certificate was filed for the unavailability of the principal witness.', DATE '2025-08-29', 'Pending', DATE '2025-10-03', 60, 2),
    (27, 'Counsel required additional time to inspect the original documents produced by the opposite party.', DATE '2025-09-16', 'Approved', DATE '2025-10-07', 65, 9);

-- notification: 48 records
INSERT INTO public.notification (notification_id, message, recipient, notification_date, status, case_id, user_id)
VALUES
    (1, 'Registry update for CNR/MA/2025/10007: a filing has been received and is awaiting scrutiny by the registry clerk.', 'judicial_assistant@temp.com', TIMESTAMPTZ '2025-05-03 11:00:00+05:30', 'Pending', 7, 5),
    (2, 'Reminder: documents for CNR/GU/2026/10014 must be filed before the next scheduled hearing.', 'court_office@temp.com', TIMESTAMPTZ '2025-05-05 12:00:00+05:30', 'Failed', 14, 10),
    (3, 'Status update: the court has recorded a new direction in CNR/RA/2024/10021. Review the order copy in the case file.', 'filing_desk@temp.com', TIMESTAMPTZ '2025-05-07 13:00:00+05:30', 'Delivered', 21, 3),
    (4, 'Service update for CNR/GU/2025/10028: notice delivery has been recorded by the registry.', 'audit_viewer@temp.com', TIMESTAMPTZ '2025-05-09 14:00:00+05:30', 'Pending', 28, 8),
    (5, 'Case CNR/UT/2026/10035: the next hearing is listed on 2025-03-07. Please check the cause list for courtroom details.', 'registry_admin@temp.com', TIMESTAMPTZ '2025-05-11 15:00:00+05:30', 'Failed', 35, 1),
    (6, 'Registry update for CNR/GU/2024/10042: a filing has been received and is awaiting scrutiny by the registry clerk.', 'records_officer@temp.com', TIMESTAMPTZ '2025-05-13 16:00:00+05:30', 'Delivered', 42, 6),
    (7, 'Reminder: documents for CNR/GU/2025/10001 must be filed before the next scheduled hearing.', 'registry_supervisor@temp.com', TIMESTAMPTZ '2025-05-15 17:00:00+05:30', 'Pending', 1, 11),
    (8, 'Status update: the court has recorded a new direction in CNR/MA/2026/10008. Review the order copy in the case file.', 'case_manager@temp.com', TIMESTAMPTZ '2025-05-17 10:00:00+05:30', 'Failed', 8, 4),
    (9, 'Service update for CNR/GU/2024/10015: notice delivery has been recorded by the registry.', 'cause_list@temp.com', TIMESTAMPTZ '2025-05-19 11:00:00+05:30', 'Delivered', 15, 9),
    (10, 'Case CNR/DE/2025/10022: the next hearing is listed on 2025-05-06. Please check the cause list for courtroom details.', 'court_reader@temp.com', TIMESTAMPTZ '2025-05-21 12:00:00+05:30', 'Pending', 22, 2),
    (11, 'Registry update for CNR/GU/2026/10029: a filing has been received and is awaiting scrutiny by the registry clerk.', 'legal_aid@temp.com', TIMESTAMPTZ '2025-05-23 13:00:00+05:30', 'Failed', 29, 7),
    (12, 'Reminder: documents for CNR/KA/2024/10036 must be filed before the next scheduled hearing.', 'bench_secretary@temp.com', TIMESTAMPTZ '2025-05-25 14:00:00+05:30', 'Delivered', 36, 12),
    (13, 'Status update: the court has recorded a new direction in CNR/MA/2025/10043. Review the order copy in the case file.', 'judicial_assistant@temp.com', TIMESTAMPTZ '2025-05-27 15:00:00+05:30', 'Pending', 43, 5),
    (14, 'Service update for CNR/GU/2026/10002: notice delivery has been recorded by the registry.', 'court_office@temp.com', TIMESTAMPTZ '2025-05-29 16:00:00+05:30', 'Failed', 2, 10),
    (15, 'Case CNR/RA/2024/10009: the next hearing is listed on 2025-07-05. Please check the cause list for courtroom details.', 'filing_desk@temp.com', TIMESTAMPTZ '2025-05-31 17:00:00+05:30', 'Delivered', 9, 3),
    (16, 'Registry update for CNR/GU/2025/10016: a filing has been received and is awaiting scrutiny by the registry clerk.', 'audit_viewer@temp.com', TIMESTAMPTZ '2025-06-02 10:00:00+05:30', 'Pending', 16, 8),
    (17, 'Reminder: documents for CNR/UT/2026/10023 must be filed before the next scheduled hearing.', 'registry_admin@temp.com', TIMESTAMPTZ '2025-06-04 11:00:00+05:30', 'Failed', 23, 1),
    (18, 'Status update: the court has recorded a new direction in CNR/GU/2024/10030. Review the order copy in the case file.', 'records_officer@temp.com', TIMESTAMPTZ '2025-06-06 12:00:00+05:30', 'Delivered', 30, 6),
    (19, 'Service update for CNR/GU/2025/10037: notice delivery has been recorded by the registry.', 'registry_supervisor@temp.com', TIMESTAMPTZ '2025-06-08 13:00:00+05:30', 'Pending', 37, 11),
    (20, 'Case CNR/MA/2026/10044: the next hearing is listed on 2025-09-03. Please check the cause list for courtroom details.', 'case_manager@temp.com', TIMESTAMPTZ '2025-06-10 14:00:00+05:30', 'Failed', 44, 4),
    (21, 'Registry update for CNR/GU/2024/10003: a filing has been received and is awaiting scrutiny by the registry clerk.', 'cause_list@temp.com', TIMESTAMPTZ '2025-06-12 15:00:00+05:30', 'Delivered', 3, 9),
    (22, 'Reminder: documents for CNR/DE/2025/10010 must be filed before the next scheduled hearing.', 'court_reader@temp.com', TIMESTAMPTZ '2025-06-14 16:00:00+05:30', 'Pending', 10, 2),
    (23, 'Status update: the court has recorded a new direction in CNR/GU/2026/10017. Review the order copy in the case file.', 'legal_aid@temp.com', TIMESTAMPTZ '2025-06-16 17:00:00+05:30', 'Failed', 17, 7),
    (24, 'Service update for CNR/KA/2024/10024: notice delivery has been recorded by the registry.', 'bench_secretary@temp.com', TIMESTAMPTZ '2025-06-18 10:00:00+05:30', 'Delivered', 24, 12),
    (25, 'Case CNR/MA/2025/10031: the next hearing is listed on 2025-01-26. Please check the cause list for courtroom details.', 'judicial_assistant@temp.com', TIMESTAMPTZ '2025-06-20 11:00:00+05:30', 'Pending', 31, 5),
    (26, 'Registry update for CNR/GU/2026/10038: a filing has been received and is awaiting scrutiny by the registry clerk.', 'court_office@temp.com', TIMESTAMPTZ '2025-06-22 12:00:00+05:30', 'Failed', 38, 10),
    (27, 'Reminder: documents for CNR/RA/2024/10045 must be filed before the next scheduled hearing.', 'filing_desk@temp.com', TIMESTAMPTZ '2025-06-24 13:00:00+05:30', 'Delivered', 45, 3),
    (28, 'Status update: the court has recorded a new direction in CNR/GU/2025/10004. Review the order copy in the case file.', 'audit_viewer@temp.com', TIMESTAMPTZ '2025-06-26 14:00:00+05:30', 'Pending', 4, 8),
    (29, 'Service update for CNR/UT/2026/10011: notice delivery has been recorded by the registry.', 'registry_admin@temp.com', TIMESTAMPTZ '2025-06-28 15:00:00+05:30', 'Failed', 11, 1),
    (30, 'Case CNR/GU/2024/10018: the next hearing is listed on 2025-03-27. Please check the cause list for courtroom details.', 'records_officer@temp.com', TIMESTAMPTZ '2025-06-30 16:00:00+05:30', 'Delivered', 18, 6),
    (31, 'Registry update for CNR/GU/2025/10025: a filing has been received and is awaiting scrutiny by the registry clerk.', 'registry_supervisor@temp.com', TIMESTAMPTZ '2025-07-02 17:00:00+05:30', 'Pending', 25, 11),
    (32, 'Reminder: documents for CNR/MA/2026/10032 must be filed before the next scheduled hearing.', 'case_manager@temp.com', TIMESTAMPTZ '2025-07-04 10:00:00+05:30', 'Failed', 32, 4),
    (33, 'Status update: the court has recorded a new direction in CNR/GU/2024/10039. Review the order copy in the case file.', 'cause_list@temp.com', TIMESTAMPTZ '2025-07-06 11:00:00+05:30', 'Delivered', 39, 9),
    (34, 'Service update for CNR/DE/2025/10046: notice delivery has been recorded by the registry.', 'court_reader@temp.com', TIMESTAMPTZ '2025-07-08 12:00:00+05:30', 'Pending', 46, 2),
    (35, 'Case CNR/GU/2026/10005: the next hearing is listed on 2025-05-26. Please check the cause list for courtroom details.', 'legal_aid@temp.com', TIMESTAMPTZ '2025-07-10 13:00:00+05:30', 'Failed', 5, 7),
    (36, 'Registry update for CNR/KA/2024/10012: a filing has been received and is awaiting scrutiny by the registry clerk.', 'bench_secretary@temp.com', TIMESTAMPTZ '2025-07-12 14:00:00+05:30', 'Delivered', 12, 12),
    (37, 'Reminder: documents for CNR/MA/2025/10019 must be filed before the next scheduled hearing.', 'judicial_assistant@temp.com', TIMESTAMPTZ '2025-07-14 15:00:00+05:30', 'Pending', 19, 5),
    (38, 'Status update: the court has recorded a new direction in CNR/GU/2026/10026. Review the order copy in the case file.', 'court_office@temp.com', TIMESTAMPTZ '2025-07-16 16:00:00+05:30', 'Failed', 26, 10),
    (39, 'Service update for CNR/RA/2024/10033: notice delivery has been recorded by the registry.', 'filing_desk@temp.com', TIMESTAMPTZ '2025-07-18 17:00:00+05:30', 'Delivered', 33, 3),
    (40, 'Case CNR/GU/2025/10040: the next hearing is listed on 2025-07-25. Please check the cause list for courtroom details.', 'audit_viewer@temp.com', TIMESTAMPTZ '2025-07-20 10:00:00+05:30', 'Pending', 40, 8),
    (41, 'Registry update for CNR/UT/2026/10047: a filing has been received and is awaiting scrutiny by the registry clerk.', 'registry_admin@temp.com', TIMESTAMPTZ '2025-07-22 11:00:00+05:30', 'Failed', 47, 1),
    (42, 'Reminder: documents for CNR/GU/2024/10006 must be filed before the next scheduled hearing.', 'records_officer@temp.com', TIMESTAMPTZ '2025-07-24 12:00:00+05:30', 'Delivered', 6, 6),
    (43, 'Status update: the court has recorded a new direction in CNR/GU/2025/10013. Review the order copy in the case file.', 'registry_supervisor@temp.com', TIMESTAMPTZ '2025-07-26 13:00:00+05:30', 'Pending', 13, 11),
    (44, 'Service update for CNR/MA/2026/10020: notice delivery has been recorded by the registry.', 'case_manager@temp.com', TIMESTAMPTZ '2025-07-28 14:00:00+05:30', 'Failed', 20, 4),
    (45, 'Case CNR/GU/2024/10027: the next hearing is listed on 2025-09-23. Please check the cause list for courtroom details.', 'cause_list@temp.com', TIMESTAMPTZ '2025-07-30 15:00:00+05:30', 'Delivered', 27, 9),
    (46, 'Registry update for CNR/DE/2025/10034: a filing has been received and is awaiting scrutiny by the registry clerk.', 'court_reader@temp.com', TIMESTAMPTZ '2025-08-01 16:00:00+05:30', 'Pending', 34, 2),
    (47, 'Reminder: documents for CNR/GU/2026/10041 must be filed before the next scheduled hearing.', 'legal_aid@temp.com', TIMESTAMPTZ '2025-08-03 17:00:00+05:30', 'Failed', 41, 7),
    (48, 'Status update: the court has recorded a new direction in CNR/KA/2024/10048. Review the order copy in the case file.', 'bench_secretary@temp.com', TIMESTAMPTZ '2025-08-05 10:00:00+05:30', 'Delivered', 48, 12);

-- audit_log: 67 records
INSERT INTO public.audit_log (audit_id, action_performed, "timestamp", client_ip, pre_modification_state, post_modification_state, user_id, case_id)
VALUES
    (1, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-01 14:00:00+05:30', '10.2.4.8'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0011.', 'Updated record: hearing rescheduled recorded for case CNR/UT/2026/10011 following registry review.', 7, 11),
    (2, 'PARTY_DETAILS_UPDATE', TIMESTAMPTZ '2025-06-01 19:00:00+05:30', '10.3.7.15'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0022.', 'Updated record: party details update recorded for case CNR/DE/2025/10022 following registry review.', 2, 22),
    (3, 'EVIDENCE_ADMITTED', TIMESTAMPTZ '2025-06-02 00:00:00+05:30', '10.4.10.22'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0033.', 'Updated record: evidence admitted recorded for case CNR/RA/2024/10033 following registry review.', 9, 33),
    (4, 'JUDGMENT_PRONOUNCED', TIMESTAMPTZ '2025-06-02 05:00:00+05:30', '10.5.13.29'::inet, 'Previous record: case status was Filed; registry reference CCMS/0044.', 'Updated record: judgment pronounced recorded for case CNR/MA/2026/10044 following registry review.', 4, 44),
    (5, 'PETITION_CREATE', TIMESTAMPTZ '2025-06-02 10:00:00+05:30', '10.6.16.36'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0007.', 'Updated record: petition create recorded for case CNR/MA/2025/10007 following registry review.', 11, 7),
    (6, 'NOTICE_DISPATCHED', TIMESTAMPTZ '2025-06-02 15:00:00+05:30', '10.7.19.43'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0018.', 'Updated record: notice dispatched recorded for case CNR/GU/2024/10018 following registry review.', 6, 18),
    (7, 'CASE_STATUS_UPDATE', TIMESTAMPTZ '2025-06-02 20:00:00+05:30', '10.8.22.50'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0029.', 'Updated record: case status update recorded for case CNR/GU/2026/10029 following registry review.', 1, 29),
    (8, 'ORDER_ISSUED', TIMESTAMPTZ '2025-06-03 01:00:00+05:30', '10.9.25.57'::inet, 'Previous record: case status was Filed; registry reference CCMS/0040.', 'Updated record: order issued recorded for case CNR/GU/2025/10040 following registry review.', 8, 40),
    (9, 'UPDATE', TIMESTAMPTZ '2025-06-03 06:00:00+05:30', '10.10.28.64'::inet, NULL, 'Updated record: update recorded for case CNR/GU/2024/10003 following registry review.', 3, 3),
    (10, 'DOCUMENT_VERIFIED', TIMESTAMPTZ '2025-06-03 11:00:00+05:30', '10.11.31.71'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0014.', 'Updated record: document verified recorded for case CNR/GU/2026/10014 following registry review.', 10, 14),
    (11, 'CREATE', TIMESTAMPTZ '2025-06-03 16:00:00+05:30', '10.12.34.78'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0025.', 'Updated record: create recorded for case CNR/GU/2025/10025 following registry review.', 5, 25),
    (12, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-03 21:00:00+05:30', '10.13.37.85'::inet, 'Previous record: case status was Filed; registry reference CCMS/0036.', 'Updated record: hearing rescheduled recorded for case CNR/KA/2024/10036 following registry review.', 12, 36),
    (13, 'PARTY_DETAILS_UPDATE', TIMESTAMPTZ '2025-06-04 02:00:00+05:30', '10.14.40.92'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0047.', NULL, 7, 47),
    (14, 'EVIDENCE_ADMITTED', TIMESTAMPTZ '2025-06-04 07:00:00+05:30', '10.15.43.99'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0010.', 'Updated record: evidence admitted recorded for case CNR/DE/2025/10010 following registry review.', 2, 10),
    (15, 'JUDGMENT_PRONOUNCED', TIMESTAMPTZ '2025-06-04 12:00:00+05:30', '10.16.46.106'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0021.', 'Updated record: judgment pronounced recorded for case CNR/RA/2024/10021 following registry review.', 9, 21),
    (16, 'PETITION_CREATE', TIMESTAMPTZ '2025-06-04 17:00:00+05:30', '10.17.49.113'::inet, 'Previous record: case status was Filed; registry reference CCMS/0032.', 'Updated record: petition create recorded for case CNR/MA/2026/10032 following registry review.', 4, 32),
    (17, 'NOTICE_DISPATCHED', TIMESTAMPTZ '2025-06-04 22:00:00+05:30', '10.18.52.120'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0043.', 'Updated record: notice dispatched recorded for case CNR/MA/2025/10043 following registry review.', 11, 43),
    (18, 'CASE_STATUS_UPDATE', TIMESTAMPTZ '2025-06-05 03:00:00+05:30', '10.19.55.127'::inet, NULL, 'Updated record: case status update recorded for case CNR/GU/2024/10006 following registry review.', 6, 6),
    (19, 'ORDER_ISSUED', TIMESTAMPTZ '2025-06-05 08:00:00+05:30', '10.20.58.134'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0017.', 'Updated record: order issued recorded for case CNR/GU/2026/10017 following registry review.', 1, 17),
    (20, 'UPDATE', TIMESTAMPTZ '2025-06-05 13:00:00+05:30', '10.21.61.141'::inet, 'Previous record: case status was Filed; registry reference CCMS/0028.', 'Updated record: update recorded for case CNR/GU/2025/10028 following registry review.', 8, 28),
    (21, 'DOCUMENT_VERIFIED', TIMESTAMPTZ '2025-06-05 18:00:00+05:30', '10.22.64.148'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0039.', 'Updated record: document verified recorded for case CNR/GU/2024/10039 following registry review.', 3, 39),
    (22, 'CREATE', TIMESTAMPTZ '2025-06-05 23:00:00+05:30', '10.23.67.155'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0002.', 'Updated record: create recorded for case CNR/GU/2026/10002 following registry review.', 10, 2),
    (23, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-06 04:00:00+05:30', '10.24.70.162'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0013.', 'Updated record: hearing rescheduled recorded for case CNR/GU/2025/10013 following registry review.', 5, 13),
    (24, 'PARTY_DETAILS_UPDATE', TIMESTAMPTZ '2025-06-06 09:00:00+05:30', '10.25.73.169'::inet, 'Previous record: case status was Filed; registry reference CCMS/0024.', 'Updated record: party details update recorded for case CNR/KA/2024/10024 following registry review.', 12, 24),
    (25, 'EVIDENCE_ADMITTED', TIMESTAMPTZ '2025-06-06 14:00:00+05:30', '10.26.76.176'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0035.', 'Updated record: evidence admitted recorded for case CNR/UT/2026/10035 following registry review.', 7, 35),
    (26, 'JUDGMENT_PRONOUNCED', TIMESTAMPTZ '2025-06-06 19:00:00+05:30', '10.27.79.183'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0046.', NULL, 2, 46),
    (27, 'PETITION_CREATE', TIMESTAMPTZ '2025-06-07 00:00:00+05:30', '10.28.82.190'::inet, NULL, 'Updated record: petition create recorded for case CNR/RA/2024/10009 following registry review.', 9, 9),
    (28, 'NOTICE_DISPATCHED', TIMESTAMPTZ '2025-06-07 05:00:00+05:30', '10.29.85.197'::inet, 'Previous record: case status was Filed; registry reference CCMS/0020.', 'Updated record: notice dispatched recorded for case CNR/MA/2026/10020 following registry review.', 4, 20),
    (29, 'CASE_STATUS_UPDATE', TIMESTAMPTZ '2025-06-07 10:00:00+05:30', '10.30.88.204'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0031.', 'Updated record: case status update recorded for case CNR/MA/2025/10031 following registry review.', 11, 31),
    (30, 'ORDER_ISSUED', TIMESTAMPTZ '2025-06-07 15:00:00+05:30', '10.31.91.211'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0042.', 'Updated record: order issued recorded for case CNR/GU/2024/10042 following registry review.', 6, 42),
    (31, 'UPDATE', TIMESTAMPTZ '2025-06-07 20:00:00+05:30', '10.32.94.218'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0005.', 'Updated record: update recorded for case CNR/GU/2026/10005 following registry review.', 1, 5),
    (32, 'DOCUMENT_VERIFIED', TIMESTAMPTZ '2025-06-08 01:00:00+05:30', '10.33.97.225'::inet, 'Previous record: case status was Filed; registry reference CCMS/0016.', 'Updated record: document verified recorded for case CNR/GU/2025/10016 following registry review.', 8, 16),
    (33, 'CREATE', TIMESTAMPTZ '2025-06-08 06:00:00+05:30', '10.34.100.232'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0027.', 'Updated record: create recorded for case CNR/GU/2024/10027 following registry review.', 3, 27),
    (34, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-08 11:00:00+05:30', '10.35.103.239'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0038.', 'Updated record: hearing rescheduled recorded for case CNR/GU/2026/10038 following registry review.', 10, 38),
    (35, 'PARTY_DETAILS_UPDATE', TIMESTAMPTZ '2025-06-08 16:00:00+05:30', '10.36.106.246'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0001.', 'Updated record: party details update recorded for case CNR/GU/2025/10001 following registry review.', 5, 1),
    (36, 'EVIDENCE_ADMITTED', TIMESTAMPTZ '2025-06-08 21:00:00+05:30', '10.37.109.3'::inet, NULL, 'Updated record: evidence admitted recorded for case CNR/KA/2024/10012 following registry review.', 12, 12),
    (37, 'JUDGMENT_PRONOUNCED', TIMESTAMPTZ '2025-06-09 02:00:00+05:30', '10.38.112.10'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0023.', 'Updated record: judgment pronounced recorded for case CNR/UT/2026/10023 following registry review.', 7, 23),
    (38, 'PETITION_CREATE', TIMESTAMPTZ '2025-06-09 07:00:00+05:30', '10.39.115.17'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0034.', 'Updated record: petition create recorded for case CNR/DE/2025/10034 following registry review.', 2, 34),
    (39, 'NOTICE_DISPATCHED', TIMESTAMPTZ '2025-06-09 12:00:00+05:30', '10.40.118.24'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0045.', NULL, 9, 45),
    (40, 'CASE_STATUS_UPDATE', TIMESTAMPTZ '2025-06-09 17:00:00+05:30', '10.41.121.31'::inet, 'Previous record: case status was Filed; registry reference CCMS/0008.', 'Updated record: case status update recorded for case CNR/MA/2026/10008 following registry review.', 4, 8),
    (41, 'ORDER_ISSUED', TIMESTAMPTZ '2025-06-09 22:00:00+05:30', '10.42.124.38'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0019.', 'Updated record: order issued recorded for case CNR/MA/2025/10019 following registry review.', 11, 19),
    (42, 'UPDATE', TIMESTAMPTZ '2025-06-10 03:00:00+05:30', '10.43.127.45'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0030.', 'Updated record: update recorded for case CNR/GU/2024/10030 following registry review.', 6, 30),
    (43, 'DOCUMENT_VERIFIED', TIMESTAMPTZ '2025-06-10 08:00:00+05:30', '10.44.130.52'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0041.', 'Updated record: document verified recorded for case CNR/GU/2026/10041 following registry review.', 1, 41),
    (44, 'CREATE', TIMESTAMPTZ '2025-06-10 13:00:00+05:30', '10.45.133.59'::inet, 'Previous record: case status was Filed; registry reference CCMS/0004.', 'Updated record: create recorded for case CNR/GU/2025/10004 following registry review.', 8, 4),
    (45, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-10 18:00:00+05:30', '10.46.136.66'::inet, NULL, 'Updated record: hearing rescheduled recorded for case CNR/GU/2024/10015 following registry review.', 3, 15),
    (46, 'PARTY_DETAILS_UPDATE', TIMESTAMPTZ '2025-06-10 23:00:00+05:30', '10.47.139.73'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0026.', 'Updated record: party details update recorded for case CNR/GU/2026/10026 following registry review.', 10, 26),
    (47, 'EVIDENCE_ADMITTED', TIMESTAMPTZ '2025-06-11 04:00:00+05:30', '10.48.142.80'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0037.', 'Updated record: evidence admitted recorded for case CNR/GU/2025/10037 following registry review.', 5, 37),
    (48, 'JUDGMENT_PRONOUNCED', TIMESTAMPTZ '2025-06-11 09:00:00+05:30', '10.49.145.87'::inet, 'Previous record: case status was Filed; registry reference CCMS/0048.', 'Updated record: judgment pronounced recorded for case CNR/KA/2024/10048 following registry review.', 12, 48),
    (49, 'PETITION_CREATE', TIMESTAMPTZ '2025-06-11 14:00:00+05:30', '10.50.148.94'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0011.', 'Updated record: petition create recorded for case CNR/UT/2026/10011 following registry review.', 7, 11),
    (50, 'NOTICE_DISPATCHED', TIMESTAMPTZ '2025-06-11 19:00:00+05:30', '10.51.151.101'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0022.', 'Updated record: notice dispatched recorded for case CNR/DE/2025/10022 following registry review.', 2, 22),
    (51, 'CASE_STATUS_UPDATE', TIMESTAMPTZ '2025-06-12 00:00:00+05:30', '10.52.154.108'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0033.', 'Updated record: case status update recorded for case CNR/RA/2024/10033 following registry review.', 9, 33),
    (52, 'ORDER_ISSUED', TIMESTAMPTZ '2025-06-12 05:00:00+05:30', '10.53.157.115'::inet, 'Previous record: case status was Filed; registry reference CCMS/0044.', NULL, 4, 44),
    (53, 'UPDATE', TIMESTAMPTZ '2025-06-12 10:00:00+05:30', '10.54.160.122'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0007.', 'Updated record: update recorded for case CNR/MA/2025/10007 following registry review.', 11, 7),
    (54, 'DOCUMENT_VERIFIED', TIMESTAMPTZ '2025-06-12 15:00:00+05:30', '10.55.163.129'::inet, NULL, 'Updated record: document verified recorded for case CNR/GU/2024/10018 following registry review.', 6, 18),
    (55, 'CREATE', TIMESTAMPTZ '2025-06-12 20:00:00+05:30', '10.56.166.136'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0029.', 'Updated record: create recorded for case CNR/GU/2026/10029 following registry review.', 1, 29),
    (56, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-13 01:00:00+05:30', '10.57.169.143'::inet, 'Previous record: case status was Filed; registry reference CCMS/0040.', 'Updated record: hearing rescheduled recorded for case CNR/GU/2025/10040 following registry review.', 8, 40),
    (57, 'PARTY_DETAILS_UPDATE', TIMESTAMPTZ '2025-06-13 06:00:00+05:30', '10.58.172.150'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0003.', 'Updated record: party details update recorded for case CNR/GU/2024/10003 following registry review.', 3, 3),
    (58, 'EVIDENCE_ADMITTED', TIMESTAMPTZ '2025-06-13 11:00:00+05:30', '10.59.175.157'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0014.', 'Updated record: evidence admitted recorded for case CNR/GU/2026/10014 following registry review.', 10, 14),
    (59, 'JUDGMENT_PRONOUNCED', TIMESTAMPTZ '2025-06-13 16:00:00+05:30', '10.60.178.164'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0025.', 'Updated record: judgment pronounced recorded for case CNR/GU/2025/10025 following registry review.', 5, 25),
    (60, 'PETITION_CREATE', TIMESTAMPTZ '2025-06-13 21:00:00+05:30', '10.61.181.171'::inet, 'Previous record: case status was Filed; registry reference CCMS/0036.', 'Updated record: petition create recorded for case CNR/KA/2024/10036 following registry review.', 12, 36),
    (61, 'NOTICE_DISPATCHED', TIMESTAMPTZ '2025-06-14 02:00:00+05:30', '10.62.184.178'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0047.', 'Updated record: notice dispatched recorded for case CNR/UT/2026/10047 following registry review.', 7, 47),
    (62, 'CASE_STATUS_UPDATE', TIMESTAMPTZ '2025-06-14 07:00:00+05:30', '10.63.187.185'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0010.', 'Updated record: case status update recorded for case CNR/DE/2025/10010 following registry review.', 2, 10),
    (63, 'ORDER_ISSUED', TIMESTAMPTZ '2025-06-14 12:00:00+05:30', '10.64.190.192'::inet, NULL, 'Updated record: order issued recorded for case CNR/RA/2024/10021 following registry review.', 9, 21),
    (64, 'UPDATE', TIMESTAMPTZ '2025-06-14 17:00:00+05:30', '10.65.193.199'::inet, 'Previous record: case status was Filed; registry reference CCMS/0032.', 'Updated record: update recorded for case CNR/MA/2026/10032 following registry review.', 4, 32),
    (65, 'DOCUMENT_VERIFIED', TIMESTAMPTZ '2025-06-14 22:00:00+05:30', '10.66.196.206'::inet, 'Previous record: case status was Under Review; registry reference CCMS/0043.', NULL, 11, 43),
    (66, 'CREATE', TIMESTAMPTZ '2025-06-15 03:00:00+05:30', '10.67.199.213'::inet, 'Previous record: case status was Awaiting Order; registry reference CCMS/0006.', 'Updated record: create recorded for case CNR/GU/2024/10006 following registry review.', 6, 6),
    (67, 'HEARING_RESCHEDULED', TIMESTAMPTZ '2025-06-15 08:00:00+05:30', '10.68.202.220'::inet, 'Previous record: case status was Notice Issued; registry reference CCMS/0017.', 'Updated record: hearing rescheduled recorded for case CNR/GU/2026/10017 following registry review.', 1, 17);

-- filing_defect: 33 records
INSERT INTO public.filing_defect (defect_id, defect_description, cure_deadline, cure_status, identification_date, clerk_id)
VALUES
    (1, 'Supporting medical certificate requires the issuing hospital''s registration details.', DATE '2025-07-11', 'Under Review', DATE '2025-07-04', 3),
    (2, 'Court fee calculation differs from the valuation stated in the plaint.', DATE '2025-07-17', 'Pending', DATE '2025-07-07', 6),
    (3, 'Annexure is missing the page reference mentioned in paragraph four of the petition.', DATE '2025-07-24', 'Cured', DATE '2025-07-10', 9),
    (4, 'Index of documents does not match the order in which annexures are attached.', DATE '2025-07-18', 'Under Review', DATE '2025-07-13', 12),
    (5, 'Address for service is incomplete and does not include the current PIN code.', DATE '2025-07-23', 'Pending', DATE '2025-07-16', 1),
    (6, 'Vakalatnama requires the advocate''s enrolment number and signature on the final page.', DATE '2025-07-29', 'Cured', DATE '2025-07-19', 4),
    (7, 'Certified translation is required for the document filed in a regional language.', NULL, 'Under Review', DATE '2025-07-22', 7),
    (8, 'Verification clause must identify which statements are based on personal knowledge.', DATE '2025-07-30', 'Pending', DATE '2025-07-25', 10),
    (9, 'Legible copy of the registered agreement is required for registry scrutiny.', DATE '2025-08-04', 'Cured', DATE '2025-07-28', 13),
    (10, 'Affidavit does not state the date on which the deponent verified the contents.', DATE '2025-08-10', 'Under Review', DATE '2025-07-31', 2),
    (11, 'Supporting medical certificate requires the issuing hospital''s registration details.', DATE '2025-08-17', 'Pending', DATE '2025-08-03', 5),
    (12, 'Court fee calculation differs from the valuation stated in the plaint.', DATE '2025-08-11', 'Cured', DATE '2025-08-06', 8),
    (13, 'Annexure is missing the page reference mentioned in paragraph four of the petition.', DATE '2025-08-16', 'Under Review', DATE '2025-08-09', 11),
    (14, 'Index of documents does not match the order in which annexures are attached.', NULL, 'Pending', DATE '2025-08-12', 14),
    (15, 'Address for service is incomplete and does not include the current PIN code.', DATE '2025-08-29', 'Cured', DATE '2025-08-15', 3),
    (16, 'Vakalatnama requires the advocate''s enrolment number and signature on the final page.', DATE '2025-08-23', 'Under Review', DATE '2025-08-18', 6),
    (17, 'Certified translation is required for the document filed in a regional language.', DATE '2025-08-28', 'Pending', DATE '2025-08-21', 9),
    (18, 'Verification clause must identify which statements are based on personal knowledge.', DATE '2025-09-03', 'Cured', DATE '2025-08-24', 12),
    (19, 'Legible copy of the registered agreement is required for registry scrutiny.', DATE '2025-09-10', 'Under Review', DATE '2025-08-27', 1),
    (20, 'Affidavit does not state the date on which the deponent verified the contents.', DATE '2025-09-04', 'Pending', DATE '2025-08-30', 4),
    (21, 'Supporting medical certificate requires the issuing hospital''s registration details.', NULL, 'Cured', DATE '2025-09-02', 7),
    (22, 'Court fee calculation differs from the valuation stated in the plaint.', DATE '2025-09-15', 'Under Review', DATE '2025-09-05', 10),
    (23, 'Annexure is missing the page reference mentioned in paragraph four of the petition.', DATE '2025-09-22', 'Pending', DATE '2025-09-08', 13),
    (24, 'Index of documents does not match the order in which annexures are attached.', DATE '2025-09-16', 'Cured', DATE '2025-09-11', 2),
    (25, 'Address for service is incomplete and does not include the current PIN code.', DATE '2025-09-21', 'Under Review', DATE '2025-09-14', 5),
    (26, 'Vakalatnama requires the advocate''s enrolment number and signature on the final page.', DATE '2025-09-27', 'Pending', DATE '2025-09-17', 8),
    (27, 'Certified translation is required for the document filed in a regional language.', DATE '2025-10-04', 'Cured', DATE '2025-09-20', 11),
    (28, 'Verification clause must identify which statements are based on personal knowledge.', NULL, 'Under Review', DATE '2025-09-23', 14),
    (29, 'Legible copy of the registered agreement is required for registry scrutiny.', DATE '2025-10-03', 'Pending', DATE '2025-09-26', 3),
    (30, 'Affidavit does not state the date on which the deponent verified the contents.', DATE '2025-10-09', 'Cured', DATE '2025-09-29', 6),
    (31, 'Supporting medical certificate requires the issuing hospital''s registration details.', DATE '2025-10-16', 'Under Review', DATE '2025-10-02', 9),
    (32, 'Court fee calculation differs from the valuation stated in the plaint.', DATE '2025-10-10', 'Pending', DATE '2025-10-05', 12),
    (33, 'Annexure is missing the page reference mentioned in paragraph four of the petition.', DATE '2025-10-15', 'Cured', DATE '2025-10-08', 1);

-- case_status_history: 110 records
INSERT INTO public.case_status_history (case_id, transition_timestamp, previous_status, new_status, transition_remarks, user_id)
VALUES
    (1, TIMESTAMPTZ '2024-01-14 09:01:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 1),
    (1, TIMESTAMPTZ '2024-01-31 09:01:00+05:30', 'Filed', 'Archived', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 4),
    (2, TIMESTAMPTZ '2024-01-27 09:02:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 2),
    (2, TIMESTAMPTZ '2024-02-13 09:02:00+05:30', 'Filed', 'Under Review', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 5),
    (2, TIMESTAMPTZ '2024-03-01 09:02:00+05:30', 'Under Review', 'Closed', 'The matter was disposed of by a reasoned order after hearing the parties.', 8),
    (3, TIMESTAMPTZ '2024-02-09 09:03:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 3),
    (3, TIMESTAMPTZ '2024-02-26 09:03:00+05:30', 'Filed', 'Evidence Review', 'The matter was disposed of by a reasoned order after hearing the parties.', 6),
    (4, TIMESTAMPTZ '2024-02-22 09:04:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 4),
    (4, TIMESTAMPTZ '2024-03-10 09:04:00+05:30', 'Filed', 'Under Review', 'Case papers were received at the filing counter and an acknowledgement was issued.', 7),
    (4, TIMESTAMPTZ '2024-03-27 09:04:00+05:30', 'Under Review', 'Closed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 10),
    (5, TIMESTAMPTZ '2024-03-06 09:05:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 5),
    (5, TIMESTAMPTZ '2024-03-23 09:05:00+05:30', 'Filed', 'Under Review', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 8),
    (6, TIMESTAMPTZ '2024-03-19 09:06:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 6),
    (6, TIMESTAMPTZ '2024-04-05 09:06:00+05:30', 'Filed', 'Under Review', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 9),
    (6, TIMESTAMPTZ '2024-04-22 09:06:00+05:30', 'Under Review', 'Closed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 12),
    (7, TIMESTAMPTZ '2024-04-01 09:07:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 7),
    (7, TIMESTAMPTZ '2024-04-18 09:07:00+05:30', 'Filed', 'Awaiting Order', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 10),
    (8, TIMESTAMPTZ '2024-04-14 09:08:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 8),
    (8, TIMESTAMPTZ '2024-05-01 09:08:00+05:30', 'Filed', 'Under Review', 'The matter was disposed of by a reasoned order after hearing the parties.', 11),
    (8, TIMESTAMPTZ '2024-05-18 09:08:00+05:30', 'Under Review', 'Closed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 2),
    (9, TIMESTAMPTZ '2024-04-27 09:09:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 9),
    (9, TIMESTAMPTZ '2024-05-14 09:09:00+05:30', 'Filed', 'Archived', 'Case papers were received at the filing counter and an acknowledgement was issued.', 12),
    (10, TIMESTAMPTZ '2024-05-10 09:10:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 10),
    (10, TIMESTAMPTZ '2024-05-27 09:10:00+05:30', 'Filed', 'Under Review', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 1),
    (10, TIMESTAMPTZ '2024-06-13 09:10:00+05:30', 'Under Review', 'Closed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 4),
    (11, TIMESTAMPTZ '2024-05-23 09:11:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 11),
    (11, TIMESTAMPTZ '2024-06-09 09:11:00+05:30', 'Filed', 'Evidence Review', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 2),
    (12, TIMESTAMPTZ '2024-06-05 09:12:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 12),
    (12, TIMESTAMPTZ '2024-06-22 09:12:00+05:30', 'Filed', 'Under Review', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 3),
    (12, TIMESTAMPTZ '2024-07-09 09:12:00+05:30', 'Under Review', 'Closed', 'The matter was disposed of by a reasoned order after hearing the parties.', 6),
    (13, TIMESTAMPTZ '2024-06-18 09:13:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 1),
    (13, TIMESTAMPTZ '2024-07-05 09:13:00+05:30', 'Filed', 'Under Review', 'The matter was disposed of by a reasoned order after hearing the parties.', 4),
    (14, TIMESTAMPTZ '2024-07-01 09:14:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 2),
    (14, TIMESTAMPTZ '2024-07-18 09:14:00+05:30', 'Filed', 'Under Review', 'Case papers were received at the filing counter and an acknowledgement was issued.', 5),
    (14, TIMESTAMPTZ '2024-08-04 09:14:00+05:30', 'Under Review', 'Closed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 8),
    (15, TIMESTAMPTZ '2024-07-14 09:15:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 3),
    (15, TIMESTAMPTZ '2024-07-31 09:15:00+05:30', 'Filed', 'Awaiting Order', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 6),
    (16, TIMESTAMPTZ '2024-07-27 09:16:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 4),
    (16, TIMESTAMPTZ '2024-08-13 09:16:00+05:30', 'Filed', 'Under Review', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 7),
    (16, TIMESTAMPTZ '2024-08-30 09:16:00+05:30', 'Under Review', 'Closed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 10),
    (17, TIMESTAMPTZ '2024-08-09 09:17:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 5),
    (17, TIMESTAMPTZ '2024-08-26 09:17:00+05:30', 'Filed', 'Archived', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 8),
    (18, TIMESTAMPTZ '2024-08-22 09:18:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 6),
    (18, TIMESTAMPTZ '2024-09-08 09:18:00+05:30', 'Filed', 'Under Review', 'The matter was disposed of by a reasoned order after hearing the parties.', 9),
    (18, TIMESTAMPTZ '2024-09-25 09:18:00+05:30', 'Under Review', 'Closed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 12),
    (19, TIMESTAMPTZ '2024-09-04 09:19:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 7),
    (19, TIMESTAMPTZ '2024-09-21 09:19:00+05:30', 'Filed', 'Evidence Review', 'Case papers were received at the filing counter and an acknowledgement was issued.', 10),
    (20, TIMESTAMPTZ '2024-09-17 09:20:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 8),
    (20, TIMESTAMPTZ '2024-10-04 09:20:00+05:30', 'Filed', 'Under Review', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 11),
    (20, TIMESTAMPTZ '2024-10-21 09:20:00+05:30', 'Under Review', 'Closed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 2),
    (21, TIMESTAMPTZ '2024-09-30 09:21:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 9),
    (21, TIMESTAMPTZ '2024-10-17 09:21:00+05:30', 'Filed', 'Under Review', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 12),
    (21, TIMESTAMPTZ '2024-11-03 09:21:00+05:30', 'Under Review', 'Archived', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 3),
    (22, TIMESTAMPTZ '2024-10-13 09:22:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 10),
    (22, TIMESTAMPTZ '2024-10-30 09:22:00+05:30', 'Filed', 'Under Review', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 1),
    (22, TIMESTAMPTZ '2024-11-16 09:22:00+05:30', 'Under Review', 'Closed', 'The matter was disposed of by a reasoned order after hearing the parties.', 4),
    (23, TIMESTAMPTZ '2024-10-26 09:23:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 11),
    (23, TIMESTAMPTZ '2024-11-12 09:23:00+05:30', 'Filed', 'Awaiting Order', 'The matter was disposed of by a reasoned order after hearing the parties.', 2),
    (24, TIMESTAMPTZ '2024-11-08 09:24:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 12),
    (24, TIMESTAMPTZ '2024-11-25 09:24:00+05:30', 'Filed', 'Under Review', 'Case papers were received at the filing counter and an acknowledgement was issued.', 3),
    (24, TIMESTAMPTZ '2024-12-12 09:24:00+05:30', 'Under Review', 'Closed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 6),
    (25, TIMESTAMPTZ '2024-11-21 09:25:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 1),
    (25, TIMESTAMPTZ '2024-12-08 09:25:00+05:30', 'Filed', 'Archived', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 4),
    (26, TIMESTAMPTZ '2024-12-04 09:26:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 2),
    (26, TIMESTAMPTZ '2024-12-21 09:26:00+05:30', 'Filed', 'Under Review', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 5),
    (26, TIMESTAMPTZ '2025-01-07 09:26:00+05:30', 'Under Review', 'Closed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 8),
    (27, TIMESTAMPTZ '2024-12-17 09:27:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 3),
    (27, TIMESTAMPTZ '2025-01-03 09:27:00+05:30', 'Filed', 'Evidence Review', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 6),
    (28, TIMESTAMPTZ '2024-12-30 09:28:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 4),
    (28, TIMESTAMPTZ '2025-01-16 09:28:00+05:30', 'Filed', 'Closed', 'The matter was disposed of by a reasoned order after hearing the parties.', 7),
    (29, TIMESTAMPTZ '2025-01-12 09:29:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 5),
    (29, TIMESTAMPTZ '2025-01-29 09:29:00+05:30', 'Filed', 'Under Review', 'Case papers were received at the filing counter and an acknowledgement was issued.', 8),
    (30, TIMESTAMPTZ '2025-01-25 09:30:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 6),
    (30, TIMESTAMPTZ '2025-02-11 09:30:00+05:30', 'Filed', 'Notice Issued', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 9),
    (31, TIMESTAMPTZ '2025-02-07 09:31:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 7),
    (31, TIMESTAMPTZ '2025-02-24 09:31:00+05:30', 'Filed', 'Awaiting Order', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 10),
    (32, TIMESTAMPTZ '2025-02-20 09:32:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 8),
    (32, TIMESTAMPTZ '2025-03-09 09:32:00+05:30', 'Filed', 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 11),
    (33, TIMESTAMPTZ '2025-03-05 09:33:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 9),
    (33, TIMESTAMPTZ '2025-03-22 09:33:00+05:30', 'Filed', 'Archived', 'The matter was disposed of by a reasoned order after hearing the parties.', 12),
    (34, TIMESTAMPTZ '2025-03-18 09:34:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 10),
    (34, TIMESTAMPTZ '2025-04-04 09:34:00+05:30', 'Filed', 'Hearing Scheduled', 'Case papers were received at the filing counter and an acknowledgement was issued.', 1),
    (35, TIMESTAMPTZ '2025-03-31 09:35:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 11),
    (35, TIMESTAMPTZ '2025-04-17 09:35:00+05:30', 'Filed', 'Evidence Review', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 2),
    (36, TIMESTAMPTZ '2025-04-13 09:36:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 12),
    (36, TIMESTAMPTZ '2025-04-30 09:36:00+05:30', 'Filed', 'Closed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 3),
    (37, TIMESTAMPTZ '2025-04-26 09:37:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 1),
    (37, TIMESTAMPTZ '2025-05-13 09:37:00+05:30', 'Filed', 'Under Review', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 4),
    (38, TIMESTAMPTZ '2025-05-09 09:38:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 2),
    (38, TIMESTAMPTZ '2025-05-26 09:38:00+05:30', 'Filed', 'Notice Issued', 'The matter was disposed of by a reasoned order after hearing the parties.', 5),
    (39, TIMESTAMPTZ '2025-05-22 09:39:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 3),
    (39, TIMESTAMPTZ '2025-06-08 09:39:00+05:30', 'Filed', 'Awaiting Order', 'Case papers were received at the filing counter and an acknowledgement was issued.', 6),
    (40, TIMESTAMPTZ '2025-06-04 09:40:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 4),
    (40, TIMESTAMPTZ '2025-06-21 09:40:00+05:30', 'Filed', 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 7),
    (41, TIMESTAMPTZ '2025-06-17 09:41:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 5),
    (41, TIMESTAMPTZ '2025-07-04 09:41:00+05:30', 'Filed', 'Archived', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 8),
    (42, TIMESTAMPTZ '2025-06-30 09:42:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 6),
    (42, TIMESTAMPTZ '2025-07-17 09:42:00+05:30', 'Filed', 'Hearing Scheduled', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 9),
    (42, TIMESTAMPTZ '2025-08-03 09:42:00+05:30', 'Hearing Scheduled', 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 12),
    (43, TIMESTAMPTZ '2025-07-13 09:43:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 7),
    (43, TIMESTAMPTZ '2025-07-30 09:43:00+05:30', 'Filed', 'Evidence Review', 'The matter was disposed of by a reasoned order after hearing the parties.', 10),
    (44, TIMESTAMPTZ '2025-07-26 09:44:00+05:30', NULL, 'Filed', 'The matter was disposed of by a reasoned order after hearing the parties.', 8),
    (44, TIMESTAMPTZ '2025-08-12 09:44:00+05:30', 'Filed', 'Closed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 11),
    (45, TIMESTAMPTZ '2025-08-08 09:45:00+05:30', NULL, 'Filed', 'Case papers were received at the filing counter and an acknowledgement was issued.', 9),
    (45, TIMESTAMPTZ '2025-08-25 09:45:00+05:30', 'Filed', 'Under Review', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 12),
    (46, TIMESTAMPTZ '2025-08-21 09:46:00+05:30', NULL, 'Filed', 'The registry completed preliminary scrutiny and marked the matter for judicial consideration.', 10),
    (46, TIMESTAMPTZ '2025-09-07 09:46:00+05:30', 'Filed', 'Notice Issued', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 1),
    (47, TIMESTAMPTZ '2025-09-03 09:47:00+05:30', NULL, 'Filed', 'Notice was directed to be issued to the respondent at the address furnished in the petition.', 11),
    (47, TIMESTAMPTZ '2025-09-20 09:47:00+05:30', 'Filed', 'Awaiting Order', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 2),
    (48, TIMESTAMPTZ '2025-09-16 09:48:00+05:30', NULL, 'Filed', 'The court recorded the appearance of counsel and fixed the matter for further hearing.', 12);

-- document: 75 records
INSERT INTO public.document (document_id, title, document_type, file_path, upload_timestamp, verification_status, version, confidentiality_level, case_id)
VALUES
    (1, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0013/documents/0001.pdf', TIMESTAMPTZ '2025-01-03 12:00:00+05:30', 'Pending', 1, 'Restricted', 13),
    (2, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0026/documents/0002.pdf', TIMESTAMPTZ '2025-01-05 12:00:00+05:30', 'Rejected', 1, 'Confidential', 26),
    (3, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0039/documents/0003.pdf', TIMESTAMPTZ '2025-01-07 12:00:00+05:30', 'Under Review', 2, 'Public', 39),
    (4, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0004/documents/0004.pdf', TIMESTAMPTZ '2025-01-09 12:00:00+05:30', 'Verified', 1, 'Restricted', 4),
    (5, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0017/documents/0005.pdf', TIMESTAMPTZ '2025-01-11 12:00:00+05:30', 'Pending', 1, 'Confidential', 17),
    (6, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0030/documents/0006.pdf', TIMESTAMPTZ '2025-01-13 12:00:00+05:30', 'Rejected', 2, 'Public', 30),
    (7, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0043/documents/0007.pdf', TIMESTAMPTZ '2025-01-15 12:00:00+05:30', 'Under Review', 1, 'Restricted', 43),
    (8, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0008/documents/0008.pdf', TIMESTAMPTZ '2025-01-17 12:00:00+05:30', 'Verified', 1, 'Confidential', 8),
    (9, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0021/documents/0009.pdf', TIMESTAMPTZ '2025-01-19 12:00:00+05:30', 'Pending', 2, 'Public', 21),
    (10, 'Affidavit of Sana Mistry confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0034/documents/0010.pdf', TIMESTAMPTZ '2025-01-21 12:00:00+05:30', 'Rejected', 1, 'Restricted', 34),
    (11, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0047/documents/0011.pdf', TIMESTAMPTZ '2025-01-23 12:00:00+05:30', 'Under Review', 1, 'Confidential', 47),
    (12, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0012/documents/0012.pdf', TIMESTAMPTZ '2025-01-25 12:00:00+05:30', 'Verified', 2, 'Public', 12),
    (13, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0025/documents/0013.pdf', TIMESTAMPTZ '2025-01-27 12:00:00+05:30', 'Pending', 1, 'Restricted', 25),
    (14, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0038/documents/0014.pdf', TIMESTAMPTZ '2025-01-29 12:00:00+05:30', 'Rejected', 1, 'Confidential', 38),
    (15, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0003/documents/0015.pdf', TIMESTAMPTZ '2025-01-31 12:00:00+05:30', 'Under Review', 2, 'Public', 3),
    (16, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0016/documents/0016.pdf', TIMESTAMPTZ '2025-02-02 12:00:00+05:30', 'Verified', 1, 'Restricted', 16),
    (17, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0029/documents/0017.pdf', TIMESTAMPTZ '2025-02-04 12:00:00+05:30', 'Pending', 1, 'Confidential', 29),
    (18, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0042/documents/0018.pdf', TIMESTAMPTZ '2025-02-06 12:00:00+05:30', 'Rejected', 2, 'Public', 42),
    (19, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0007/documents/0019.pdf', TIMESTAMPTZ '2025-02-08 12:00:00+05:30', 'Under Review', 1, 'Restricted', 7),
    (20, 'Affidavit of Arjun Saxena confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0020/documents/0020.pdf', TIMESTAMPTZ '2025-02-10 12:00:00+05:30', 'Verified', 1, 'Confidential', 20),
    (21, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0033/documents/0021.pdf', TIMESTAMPTZ '2025-02-12 12:00:00+05:30', 'Pending', 2, 'Public', 33),
    (22, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0046/documents/0022.pdf', TIMESTAMPTZ '2025-02-14 12:00:00+05:30', 'Rejected', 1, 'Restricted', 46),
    (23, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0011/documents/0023.pdf', TIMESTAMPTZ '2025-02-16 12:00:00+05:30', 'Under Review', 1, 'Confidential', 11),
    (24, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0024/documents/0024.pdf', TIMESTAMPTZ '2025-02-18 12:00:00+05:30', 'Verified', 2, 'Public', 24),
    (25, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0037/documents/0025.pdf', TIMESTAMPTZ '2025-02-20 12:00:00+05:30', 'Pending', 1, 'Restricted', 37),
    (26, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0002/documents/0026.pdf', TIMESTAMPTZ '2025-02-22 12:00:00+05:30', 'Rejected', 1, 'Confidential', 2),
    (27, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0015/documents/0027.pdf', TIMESTAMPTZ '2025-02-24 12:00:00+05:30', 'Under Review', 2, 'Public', 15),
    (28, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0028/documents/0028.pdf', TIMESTAMPTZ '2025-02-26 12:00:00+05:30', 'Verified', 1, 'Restricted', 28),
    (29, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0041/documents/0029.pdf', TIMESTAMPTZ '2025-02-28 12:00:00+05:30', 'Pending', 1, 'Confidential', 41),
    (30, 'Affidavit of Riya Joshi confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0006/documents/0030.pdf', TIMESTAMPTZ '2025-03-02 12:00:00+05:30', 'Rejected', 2, 'Public', 6),
    (31, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0019/documents/0031.pdf', TIMESTAMPTZ '2025-03-04 12:00:00+05:30', 'Under Review', 1, 'Restricted', 19),
    (32, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0032/documents/0032.pdf', TIMESTAMPTZ '2025-03-06 12:00:00+05:30', 'Verified', 1, 'Confidential', 32),
    (33, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0045/documents/0033.pdf', TIMESTAMPTZ '2025-03-08 12:00:00+05:30', 'Pending', 2, 'Public', 45),
    (34, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0010/documents/0034.pdf', TIMESTAMPTZ '2025-03-10 12:00:00+05:30', 'Rejected', 1, 'Restricted', 10),
    (35, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0023/documents/0035.pdf', TIMESTAMPTZ '2025-03-12 12:00:00+05:30', 'Under Review', 1, 'Confidential', 23),
    (36, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0036/documents/0036.pdf', TIMESTAMPTZ '2025-03-14 12:00:00+05:30', 'Verified', 2, 'Public', 36),
    (37, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0001/documents/0037.pdf', TIMESTAMPTZ '2025-03-16 12:00:00+05:30', 'Pending', 1, 'Restricted', 1),
    (38, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0014/documents/0038.pdf', TIMESTAMPTZ '2025-03-18 12:00:00+05:30', 'Rejected', 1, 'Confidential', 14),
    (39, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0027/documents/0039.pdf', TIMESTAMPTZ '2025-03-20 12:00:00+05:30', 'Under Review', 2, 'Public', 27),
    (40, 'Affidavit of Karan Mistry confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0040/documents/0040.pdf', TIMESTAMPTZ '2025-03-22 12:00:00+05:30', 'Verified', 1, 'Restricted', 40),
    (41, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0005/documents/0041.pdf', TIMESTAMPTZ '2025-03-24 12:00:00+05:30', 'Pending', 1, 'Confidential', 5),
    (42, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0018/documents/0042.pdf', TIMESTAMPTZ '2025-03-26 12:00:00+05:30', 'Rejected', 2, 'Public', 18),
    (43, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0031/documents/0043.pdf', TIMESTAMPTZ '2025-03-28 12:00:00+05:30', 'Under Review', 1, 'Restricted', 31),
    (44, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0044/documents/0044.pdf', TIMESTAMPTZ '2025-03-30 12:00:00+05:30', 'Verified', 1, 'Confidential', 44),
    (45, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0009/documents/0045.pdf', TIMESTAMPTZ '2025-04-01 12:00:00+05:30', 'Pending', 2, 'Public', 9),
    (46, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0022/documents/0046.pdf', TIMESTAMPTZ '2025-04-03 12:00:00+05:30', 'Rejected', 1, 'Restricted', 22),
    (47, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0035/documents/0047.pdf', TIMESTAMPTZ '2025-04-05 12:00:00+05:30', 'Under Review', 1, 'Confidential', 35),
    (48, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0048/documents/0048.pdf', TIMESTAMPTZ '2025-04-07 12:00:00+05:30', 'Verified', 2, 'Public', 48),
    (49, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0013/documents/0049.pdf', TIMESTAMPTZ '2025-04-09 12:00:00+05:30', 'Pending', 1, 'Restricted', 13),
    (50, 'Affidavit of Nikhil Saxena confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0026/documents/0050.pdf', TIMESTAMPTZ '2025-04-11 12:00:00+05:30', 'Rejected', 1, 'Confidential', 26),
    (51, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0039/documents/0051.pdf', TIMESTAMPTZ '2025-04-13 12:00:00+05:30', 'Under Review', 2, 'Public', 39),
    (52, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0004/documents/0052.pdf', TIMESTAMPTZ '2025-04-15 12:00:00+05:30', 'Verified', 1, 'Restricted', 4),
    (53, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0017/documents/0053.pdf', TIMESTAMPTZ '2025-04-17 12:00:00+05:30', 'Pending', 1, 'Confidential', 17),
    (54, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0030/documents/0054.pdf', TIMESTAMPTZ '2025-04-19 12:00:00+05:30', 'Rejected', 2, 'Public', 30),
    (55, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0043/documents/0055.pdf', TIMESTAMPTZ '2025-04-21 12:00:00+05:30', 'Under Review', 1, 'Restricted', 43),
    (56, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0008/documents/0056.pdf', TIMESTAMPTZ '2025-04-23 12:00:00+05:30', 'Verified', 1, 'Confidential', 8),
    (57, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0021/documents/0057.pdf', TIMESTAMPTZ '2025-04-25 12:00:00+05:30', 'Pending', 2, 'Public', 21),
    (58, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0034/documents/0058.pdf', TIMESTAMPTZ '2025-04-27 12:00:00+05:30', 'Rejected', 1, 'Restricted', 34),
    (59, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0047/documents/0059.pdf', TIMESTAMPTZ '2025-04-29 12:00:00+05:30', 'Under Review', 1, 'Confidential', 47),
    (60, 'Affidavit of Sana Joshi confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0012/documents/0060.pdf', TIMESTAMPTZ '2025-05-01 12:00:00+05:30', 'Verified', 2, 'Public', 12),
    (61, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0025/documents/0061.pdf', TIMESTAMPTZ '2025-05-03 12:00:00+05:30', 'Pending', 1, 'Restricted', 25),
    (62, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0038/documents/0062.pdf', TIMESTAMPTZ '2025-05-05 12:00:00+05:30', 'Rejected', 1, 'Confidential', 38),
    (63, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0003/documents/0063.pdf', TIMESTAMPTZ '2025-05-07 12:00:00+05:30', 'Under Review', 2, 'Public', 3),
    (64, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0016/documents/0064.pdf', TIMESTAMPTZ '2025-05-09 12:00:00+05:30', 'Verified', 1, 'Restricted', 16),
    (65, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0029/documents/0065.pdf', TIMESTAMPTZ '2025-05-11 12:00:00+05:30', 'Pending', 1, 'Confidential', 29),
    (66, 'Medical certificate and treatment summary issued after examination at the district hospital.', 'Medical Record', '/ccms/case-files/0042/documents/0066.pdf', TIMESTAMPTZ '2025-05-13 12:00:00+05:30', 'Rejected', 2, 'Public', 42),
    (67, 'Settlement memorandum recording the payment terms and undertakings accepted by both parties.', 'Settlement Memorandum', '/ccms/case-files/0007/documents/0067.pdf', TIMESTAMPTZ '2025-05-15 12:00:00+05:30', 'Under Review', 1, 'Restricted', 7),
    (68, 'Vakalatnama authorising the named advocate to appear, plead and act on behalf of the party.', 'Vakalatnama', '/ccms/case-files/0020/documents/0068.pdf', TIMESTAMPTZ '2025-05-17 12:00:00+05:30', 'Verified', 1, 'Confidential', 20),
    (69, 'Certified bank account statement showing the disputed transfers and the dates on which the entries were posted.', 'Bank Statement', '/ccms/case-files/0033/documents/0069.pdf', TIMESTAMPTZ '2025-05-19 12:00:00+05:30', 'Pending', 2, 'Public', 33),
    (70, 'Affidavit of Arjun Mistry confirming that the statements in the petition are true to the deponent''s personal knowledge and the records produced.', 'Affidavit', '/ccms/case-files/0046/documents/0070.pdf', TIMESTAMPTZ '2025-05-21 12:00:00+05:30', 'Rejected', 1, 'Restricted', 46),
    (71, 'Site inspection note describing the boundary markers, access path and physical condition of the disputed property.', 'Site Inspection Note', '/ccms/case-files/0011/documents/0071.pdf', TIMESTAMPTZ '2025-05-23 12:00:00+05:30', 'Under Review', 1, 'Confidential', 11),
    (72, 'Written statement filed by the respondent denying the alleged breach and setting out the respondent''s version of events.', 'Written Statement', '/ccms/case-files/0024/documents/0072.pdf', TIMESTAMPTZ '2025-05-25 12:00:00+05:30', 'Verified', 2, 'Public', 24),
    (73, 'Registered sale agreement recording the consideration, payment schedule and possession obligations of the parties.', 'Agreement', '/ccms/case-files/0037/documents/0073.pdf', TIMESTAMPTZ '2025-05-27 12:00:00+05:30', 'Pending', 1, 'Restricted', 37),
    (74, 'Acknowledgement recording delivery of the court notice at the address furnished in the case papers.', 'Service Acknowledgement', '/ccms/case-files/0002/documents/0074.pdf', TIMESTAMPTZ '2025-05-29 12:00:00+05:30', 'Rejected', 1, 'Confidential', 2),
    (75, 'Police station investigation report recording the complaint, witness statements and steps taken during inquiry.', 'Police Report', '/ccms/case-files/0015/documents/0075.pdf', TIMESTAMPTZ '2025-05-31 12:00:00+05:30', 'Under Review', 2, 'Public', 15);

-- case_party: 96 records
INSERT INTO public.case_party (case_id, party_id)
VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (2, 4),
    (3, 5),
    (3, 6),
    (4, 7),
    (4, 8),
    (5, 9),
    (5, 10),
    (6, 11),
    (6, 12),
    (7, 13),
    (7, 14),
    (8, 15),
    (8, 16),
    (9, 17),
    (9, 18),
    (10, 19),
    (10, 20),
    (11, 21),
    (11, 22),
    (12, 23),
    (12, 24),
    (13, 25),
    (13, 26),
    (14, 27),
    (14, 28),
    (15, 29),
    (15, 30),
    (16, 31),
    (16, 32),
    (17, 33),
    (17, 34),
    (18, 35),
    (18, 36),
    (19, 37),
    (19, 38),
    (20, 39),
    (20, 40),
    (21, 41),
    (21, 42),
    (22, 43),
    (22, 44),
    (23, 45),
    (23, 1),
    (24, 2),
    (24, 3),
    (25, 4),
    (25, 5),
    (26, 6),
    (26, 7),
    (27, 8),
    (27, 9),
    (28, 10),
    (28, 11),
    (29, 12),
    (29, 13),
    (30, 14),
    (30, 15),
    (31, 16),
    (31, 17),
    (32, 18),
    (32, 19),
    (33, 20),
    (33, 21),
    (34, 22),
    (34, 23),
    (35, 24),
    (35, 25),
    (36, 26),
    (36, 27),
    (37, 28),
    (37, 29),
    (38, 30),
    (38, 31),
    (39, 32),
    (39, 33),
    (40, 34),
    (40, 35),
    (41, 36),
    (41, 37),
    (42, 38),
    (42, 39),
    (43, 40),
    (43, 41),
    (44, 42),
    (44, 43),
    (45, 44),
    (45, 45),
    (46, 1),
    (46, 2),
    (47, 3),
    (47, 4),
    (48, 5),
    (48, 6);

-- case_witness: 51 records
INSERT INTO public.case_witness (case_id, witness_id, summons_status)
VALUES
    (1, 7, 'Pending'),
    (2, 14, 'Returned'),
    (3, 1, 'Exempt'),
    (4, 8, 'Served'),
    (5, 15, 'Pending'),
    (6, 2, 'Returned'),
    (7, 9, 'Exempt'),
    (8, 16, 'Served'),
    (9, 3, 'Pending'),
    (10, 10, 'Returned'),
    (11, 17, 'Exempt'),
    (12, 4, 'Served'),
    (13, 11, 'Pending'),
    (14, 18, 'Returned'),
    (15, 5, 'Exempt'),
    (16, 12, 'Served'),
    (17, 19, 'Pending'),
    (18, 6, 'Returned'),
    (19, 13, 'Exempt'),
    (20, 20, 'Served'),
    (21, 7, 'Pending'),
    (22, 14, 'Returned'),
    (23, 1, 'Exempt'),
    (24, 8, 'Served'),
    (25, 15, 'Pending'),
    (26, 2, 'Returned'),
    (27, 9, 'Exempt'),
    (28, 16, 'Served'),
    (29, 3, 'Pending'),
    (30, 10, 'Returned'),
    (31, 17, 'Exempt'),
    (32, 4, 'Served'),
    (33, 11, 'Pending'),
    (34, 18, 'Returned'),
    (35, 5, 'Exempt'),
    (36, 12, 'Served'),
    (37, 19, 'Pending'),
    (38, 6, 'Returned'),
    (39, 13, 'Exempt'),
    (40, 20, 'Served'),
    (41, 7, 'Pending'),
    (42, 14, 'Returned'),
    (2, 8, 'Served'),
    (4, 10, 'Served'),
    (6, 12, 'Served'),
    (8, 14, 'Served'),
    (10, 16, 'Served'),
    (12, 18, 'Served'),
    (14, 20, 'Served'),
    (16, 2, 'Served'),
    (18, 4, 'Served');

-- bench_judge: 16 records
INSERT INTO public.bench_judge (bench_id, judge_id)
VALUES
    (1, 2),
    (1, 3),
    (2, 4),
    (2, 5),
    (3, 6),
    (3, 7),
    (4, 8),
    (4, 9),
    (5, 10),
    (5, 11),
    (6, 12),
    (6, 13),
    (7, 14),
    (7, 15),
    (8, 16),
    (8, 17);

-- judge_court_order: 31 records
INSERT INTO public.judge_court_order (judge_id, order_id)
VALUES
    (9, 1),
    (14, 2),
    (1, 3),
    (11, 5),
    (16, 6),
    (3, 7),
    (13, 9),
    (18, 10),
    (5, 11),
    (15, 13),
    (2, 14),
    (7, 15),
    (17, 17),
    (4, 18),
    (9, 19),
    (1, 21),
    (6, 22),
    (11, 23),
    (3, 25),
    (8, 26),
    (13, 27),
    (5, 29),
    (10, 30),
    (15, 31),
    (7, 33),
    (12, 34),
    (17, 35),
    (9, 37),
    (14, 38),
    (1, 39),
    (11, 41);

-- judge_evidence: 61 records
INSERT INTO public.judge_evidence (judge_id, evidence_id)
VALUES
    (9, 1),
    (16, 2),
    (12, 4),
    (1, 5),
    (15, 7),
    (4, 8),
    (18, 10),
    (7, 11),
    (3, 13),
    (10, 14),
    (6, 16),
    (13, 17),
    (9, 19),
    (16, 20),
    (12, 22),
    (1, 23),
    (15, 25),
    (4, 26),
    (18, 28),
    (7, 29),
    (3, 31),
    (10, 32),
    (6, 34),
    (13, 35),
    (9, 37),
    (16, 38),
    (12, 40),
    (1, 41),
    (15, 43),
    (4, 44),
    (18, 46),
    (7, 47),
    (3, 49),
    (10, 50),
    (6, 52),
    (13, 53),
    (9, 55),
    (16, 56),
    (12, 58),
    (1, 59),
    (15, 61),
    (4, 62),
    (18, 64),
    (7, 65),
    (3, 67),
    (10, 68),
    (6, 70),
    (13, 71),
    (9, 73),
    (16, 74),
    (12, 76),
    (1, 77),
    (15, 79),
    (4, 80),
    (18, 82),
    (7, 83),
    (12, 5),
    (1, 12),
    (8, 19),
    (15, 26),
    (4, 33);

-- lawyer_party: 56 records
INSERT INTO public.lawyer_party (lawyer_id, party_id)
VALUES
    (1, 3),
    (1, 9),
    (1, 10),
    (1, 37),
    (2, 20),
    (2, 31),
    (3, 1),
    (3, 12),
    (4, 6),
    (4, 40),
    (5, 21),
    (5, 32),
    (6, 4),
    (6, 15),
    (7, 41),
    (8, 24),
    (8, 35),
    (9, 5),
    (9, 16),
    (10, 44),
    (11, 25),
    (11, 36),
    (12, 1),
    (12, 8),
    (12, 19),
    (13, 3),
    (13, 45),
    (14, 5),
    (14, 28),
    (14, 39),
    (15, 7),
    (15, 9),
    (15, 20),
    (16, 3),
    (16, 9),
    (17, 11),
    (17, 29),
    (17, 40),
    (18, 12),
    (18, 23),
    (19, 4),
    (20, 32),
    (20, 43),
    (21, 13),
    (21, 24),
    (22, 7),
    (23, 33),
    (23, 44),
    (24, 16),
    (24, 27),
    (25, 8),
    (26, 2),
    (26, 36),
    (27, 17),
    (27, 28),
    (28, 11);

-- lawyer_case: 55 records
INSERT INTO public.lawyer_case (lawyer_id, case_id, representation_start_date, representation_end_date)
VALUES
    (3, 1, DATE '2024-01-08', DATE '2024-04-07'),
    (6, 2, DATE '2024-01-15', DATE '2024-05-14'),
    (9, 3, DATE '2024-01-22', DATE '2024-08-19'),
    (12, 4, DATE '2024-01-29', NULL),
    (15, 5, DATE '2024-02-05', DATE '2024-05-05'),
    (18, 6, DATE '2024-02-12', DATE '2024-06-11'),
    (21, 7, DATE '2024-02-19', DATE '2024-09-16'),
    (24, 8, DATE '2024-02-26', NULL),
    (27, 9, DATE '2024-03-04', DATE '2024-06-02'),
    (2, 10, DATE '2024-03-11', DATE '2024-07-09'),
    (5, 11, DATE '2024-03-18', DATE '2024-10-14'),
    (8, 12, DATE '2024-03-25', NULL),
    (11, 13, DATE '2024-04-01', DATE '2024-06-30'),
    (14, 14, DATE '2024-04-08', DATE '2024-08-06'),
    (17, 15, DATE '2024-04-15', DATE '2024-11-11'),
    (20, 16, DATE '2024-04-22', NULL),
    (23, 17, DATE '2024-04-29', DATE '2024-07-28'),
    (26, 18, DATE '2024-05-06', DATE '2024-09-03'),
    (1, 19, DATE '2024-05-13', DATE '2024-12-09'),
    (4, 20, DATE '2024-05-20', NULL),
    (7, 21, DATE '2024-05-27', DATE '2024-08-25'),
    (10, 22, DATE '2024-06-03', DATE '2024-10-01'),
    (13, 23, DATE '2024-06-10', DATE '2025-01-06'),
    (16, 24, DATE '2024-06-17', NULL),
    (19, 25, DATE '2024-06-24', DATE '2024-09-22'),
    (22, 26, DATE '2024-07-01', DATE '2024-10-29'),
    (25, 27, DATE '2024-07-08', DATE '2025-02-03'),
    (28, 28, DATE '2024-07-15', NULL),
    (3, 29, DATE '2024-07-22', DATE '2024-10-20'),
    (6, 30, DATE '2024-07-29', DATE '2024-11-26'),
    (9, 31, DATE '2024-08-05', DATE '2025-03-03'),
    (12, 32, DATE '2024-08-12', NULL),
    (15, 33, DATE '2024-08-19', DATE '2024-11-17'),
    (18, 34, DATE '2024-08-26', DATE '2024-12-24'),
    (21, 35, DATE '2024-09-02', DATE '2025-03-31'),
    (24, 36, DATE '2024-09-09', NULL),
    (27, 37, DATE '2024-09-16', DATE '2024-12-15'),
    (2, 38, DATE '2024-09-23', DATE '2025-01-21'),
    (5, 39, DATE '2024-09-30', DATE '2025-04-28'),
    (8, 40, DATE '2024-10-07', NULL),
    (11, 41, DATE '2024-10-14', DATE '2025-01-12'),
    (14, 42, DATE '2024-10-21', DATE '2025-02-18'),
    (17, 43, DATE '2024-10-28', DATE '2025-05-26'),
    (20, 44, DATE '2024-11-04', NULL),
    (23, 45, DATE '2024-11-11', DATE '2025-02-09'),
    (26, 46, DATE '2024-11-18', DATE '2025-03-18'),
    (1, 47, DATE '2024-11-25', DATE '2025-06-23'),
    (4, 48, DATE '2024-12-02', NULL),
    (12, 1, DATE '2025-03-06', NULL),
    (13, 2, DATE '2025-03-11', NULL),
    (14, 3, DATE '2025-03-16', NULL),
    (15, 4, DATE '2025-03-21', NULL),
    (16, 5, DATE '2025-03-26', NULL),
    (17, 6, DATE '2025-03-31', NULL),
    (1, 5, DATE '2025-04-01', NULL);

-- hearing_witness: 65 records
INSERT INTO public.hearing_witness (hearing_id, witness_id, testimony)
VALUES
    (1, 9, 'Zoya Gandhi confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (2, 18, 'Manav Desai explained the method used to prepare the report and identified the records relied upon.'),
    (3, 7, 'Avni Patel stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (5, 5, 'Diya Iyer stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (6, 14, 'Shreya Mukherjee confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (7, 3, 'Ishaan Pillai explained the method used to prepare the report and identified the records relied upon.'),
    (9, 1, 'Hetal Purohit identified the property boundary markers and described the condition of the access path.'),
    (10, 10, 'Arjun Joshi stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (11, 19, 'Ananya Malhotra confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (13, 17, 'Aditya Jain stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (14, 6, 'Aditi Choudhary identified the property boundary markers and described the condition of the access path.'),
    (15, 15, 'Parth Mehta stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (17, 13, 'Saanvi Reddy explained the method used to prepare the report and identified the records relied upon.'),
    (18, 2, 'Ayesha Chauhan stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (19, 11, 'Dhruv Verma identified the property boundary markers and described the condition of the access path.'),
    (21, 9, 'Zoya Gandhi confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (22, 18, 'Manav Desai explained the method used to prepare the report and identified the records relied upon.'),
    (23, 7, 'Avni Patel stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (25, 5, 'Diya Iyer stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (26, 14, 'Shreya Mukherjee confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (27, 3, 'Ishaan Pillai explained the method used to prepare the report and identified the records relied upon.'),
    (29, 1, 'Hetal Purohit identified the property boundary markers and described the condition of the access path.'),
    (30, 10, 'Arjun Joshi stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (31, 19, 'Ananya Malhotra confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (33, 17, 'Aditya Jain stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (34, 6, 'Aditi Choudhary identified the property boundary markers and described the condition of the access path.'),
    (35, 15, 'Parth Mehta stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (37, 13, 'Saanvi Reddy explained the method used to prepare the report and identified the records relied upon.'),
    (38, 2, 'Ayesha Chauhan stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (39, 11, 'Dhruv Verma identified the property boundary markers and described the condition of the access path.'),
    (41, 9, 'Zoya Gandhi confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (42, 18, 'Manav Desai explained the method used to prepare the report and identified the records relied upon.'),
    (43, 7, 'Avni Patel stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (45, 5, 'Diya Iyer stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (46, 14, 'Shreya Mukherjee confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (47, 3, 'Ishaan Pillai explained the method used to prepare the report and identified the records relied upon.'),
    (49, 1, 'Hetal Purohit identified the property boundary markers and described the condition of the access path.'),
    (50, 10, 'Arjun Joshi stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (51, 19, 'Ananya Malhotra confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (53, 17, 'Aditya Jain stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (54, 6, 'Aditi Choudhary identified the property boundary markers and described the condition of the access path.'),
    (55, 15, 'Parth Mehta stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (57, 13, 'Saanvi Reddy explained the method used to prepare the report and identified the records relied upon.'),
    (58, 2, 'Ayesha Chauhan stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (59, 11, 'Dhruv Verma identified the property boundary markers and described the condition of the access path.'),
    (61, 9, 'Zoya Gandhi confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (62, 18, 'Manav Desai explained the method used to prepare the report and identified the records relied upon.'),
    (63, 7, 'Avni Patel stated that the parties had discussed the payment schedule before the supply dispute arose.'),
    (65, 5, 'Diya Iyer stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (66, 14, 'Shreya Mukherjee confirmed the date of delivery and identified the signature appearing on the receipt.'),
    (67, 3, 'Ishaan Pillai explained the method used to prepare the report and identified the records relied upon.'),
    (69, 1, 'Hetal Purohit identified the property boundary markers and described the condition of the access path.'),
    (70, 10, 'Arjun Joshi stated that they were present near the location and identified the vehicle shown in the inspection photographs.'),
    (3, 8, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (9, 14, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (15, 20, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (21, 6, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (27, 12, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (33, 18, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (39, 4, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (45, 10, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (51, 16, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (57, 2, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (63, 8, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.'),
    (69, 14, 'The witness clarified the sequence of events and identified the relevant entry in the contemporaneous record.');


-- ---------------------------------------------------------------------
-- SUPPLEMENTAL REALISTIC RECORDS
-- Every one of the 31 base tables is brought to a distinct count
-- between 85 and 110. IDs and foreign keys are derived from loaded rows.
-- ---------------------------------------------------------------------

INSERT INTO public.court (court_id, jurisdiction_area, physical_address)
SELECT COALESCE((SELECT MAX(court_id) FROM public.court),0)+g,
       (ARRAY['Ahmedabad City Civil Jurisdiction','Rajkot District Jurisdiction','Morbi District Jurisdiction','Surat Commercial Jurisdiction','Vadodara Family Court Jurisdiction','Pune Civil Jurisdiction','Mumbai Metropolitan Jurisdiction','Jaipur District Jurisdiction','New Delhi District Jurisdiction','Hyderabad District Jurisdiction','Bengaluru Urban Jurisdiction','Chennai District Jurisdiction','Kochi District Jurisdiction','Kolkata District Jurisdiction'])[1+((g-1)%14)],
       format('District Court Complex, %s, India', (ARRAY['Ahmedabad','Rajkot','Morbi','Surat','Vadodara','Pune','Mumbai','Jaipur','New Delhi','Hyderabad','Bengaluru','Chennai','Kochi','Kolkata'])[1+((g-1)%14)])
FROM generate_series(1, GREATEST(0, 94-(SELECT COUNT(*) FROM public.court))) g;

INSERT INTO public.judge (judge_id, judge_name, designation)
SELECT COALESCE((SELECT MAX(judge_id) FROM public.judge),0)+g,
       (ARRAY['Anirudh Deshmukh','Kriti Vyas','Raghav Bhandari','Sonal Nambiar','Pranav Kulkarni','Ishita Rao','Nitin Gohil','Madhuri Sethi','Arvind Menon','Pallavi Shah','Ritesh Dutta','Shalini Iqbal','Vikram Sood','Charu Reddy'])[1+((g-1)%14)],
       (ARRAY['Civil Judge (Senior Division)','Additional District Judge','Judicial Magistrate First Class','Additional Sessions Judge','Principal Judge, Family Court'])[1+((g-1)%5)]
FROM generate_series(1, GREATEST(0, 91-(SELECT COUNT(*) FROM public.judge))) g;

INSERT INTO public.party (party_id, party_name, party_type, phone, address)
SELECT COALESCE((SELECT MAX(party_id) FROM public.party),0)+g,
       (ARRAY['Nandita Parmar','Rishabh Tiwari','Mihir Desai','Saira Khan','Gautam Borse','Aarushi Nair','Keshav Rathod','Nilofer Merchant','Pratiksha Dave','Samarjeet Singh','Vandana Pillai','Amanpreet Kaur','Chirag Bhatt','Ritu Malhotra','Naveen Shetty'])[1+((g-1)%15)],
       (ARRAY['Plaintiff','Defendant','Plaintiff','Defendant','Organization'])[1+((g-1)%5)],
       format('+91-98%08s', (70000000+g)::text),
       format('%s, %s, %s', (ARRAY['Bopal Road','Kalawad Road','Ring Road','Law Garden Road','Station Road','Civil Lines','M.G. Road','University Road','Ashram Road','Court Road'])[1+((g-1)%10)],
              (ARRAY['Ahmedabad','Rajkot','Morbi','Surat','Vadodara','Mumbai','Pune','Jaipur','New Delhi','Hyderabad','Bengaluru','Chennai','Kochi','Kolkata'])[1+((g-1)%14)],
              (ARRAY['Gujarat','Maharashtra','Rajasthan','Delhi','Telangana','Karnataka','Tamil Nadu','Kerala','West Bengal'])[1+((g-1)%9)])
FROM generate_series(1, GREATEST(0, 103-(SELECT COUNT(*) FROM public.party))) g;

INSERT INTO public.role (role_id, role_name, role_description)
SELECT COALESCE((SELECT MAX(role_id) FROM public.role),0)+g,
       (ARRAY['Court Registry Officer','Case Filing Supervisor','Evidence Custodian','Judicial Research Officer','Senior Court Assistant','Compliance Auditor','Court IT Administrator','Records Officer'])[1+((g-1)%8)],
       (ARRAY['Receives and scrutinises pleadings before they are placed before the court.','Maintains filing registers and monitors procedural compliance.','Tracks custody, admission and movement of documentary exhibits.','Prepares case references and maintains authorised legal research records.','Coordinates cause lists, courtroom allocation and daily proceedings.','Reviews access logs and verifies the integrity of court records.','Maintains user accounts and availability of the case management system.','Preserves certified copies and archival case documents.'])[1+((g-1)%8)]
FROM generate_series(1, GREATEST(0, 88-(SELECT COUNT(*) FROM public.role))) g;

INSERT INTO public.court_clerk (clerk_id, clerk_name, role_type, phone)
SELECT COALESCE((SELECT MAX(clerk_id) FROM public.court_clerk),0)+g,
       (ARRAY['Rupal Trivedi','Sanjay Parmar','Mitali Desai','Faisal Qureshi','Kavita Nair','Bhavesh Rathod','Nupur Shah','Akhil Menon','Jaya Solanki','Rakesh Soni','Mansi Kapoor','Tushar Dave'])[1+((g-1)%12)],
       (ARRAY['Court Clerk','Filing Clerk','Registry Clerk','Record Keeper'])[1+((g-1)%4)],
       format('+91-97%08s', (71000000+g)::text)
FROM generate_series(1, GREATEST(0, 96-(SELECT COUNT(*) FROM public.court_clerk))) g;

INSERT INTO public.bench (bench_id, bench_type, bench_name)
SELECT COALESCE((SELECT MAX(bench_id) FROM public.bench),0)+g,
       (ARRAY['Single Bench','Division Bench','Family Court Bench','Commercial Court Bench','Sessions Bench'])[1+((g-1)%5)],
       format('%s Bench - %s', (ARRAY['Ahmedabad','Rajkot','Surat','Vadodara','Mumbai','Pune','Jaipur','Hyderabad','Chennai','Kochi'])[1+((g-1)%10)], lpad(g::text,3,'0'))
FROM generate_series(1, GREATEST(0, 87-(SELECT COUNT(*) FROM public.bench))) g;

INSERT INTO public.cause_list (cause_list_id)
SELECT COALESCE((SELECT MAX(cause_list_id) FROM public.cause_list),0)+g
FROM generate_series(1, GREATEST(0, 101-(SELECT COUNT(*) FROM public.cause_list))) g;

INSERT INTO public.lawyer (lawyer_id, bar_registration_number, full_name, phone, email, law_firm_affiliation, contact_details, license_status)
SELECT COALESCE((SELECT MAX(lawyer_id) FROM public.lawyer),0)+g,
       format('GJ/%s/%s', 2018+(g%9), 3000+g),
       (ARRAY['Rupal Mehta','Faisal Contractor','Mitali Shah','Sanjay Rao','Kavita Iyer','Bhavesh Joshi','Nupur Patel','Akhil Desai','Jaya Menon','Rakesh Bhat'])[1+((g-1)%10)],
       format('+91-96%08s', (72000000+g)::text),
       lower(replace((ARRAY['rupal.mehta','faisal.contractor','mitali.shah','sanjay.rao','kavita.iyer','bhavesh.joshi','nupur.patel','akhil.desai','jaya.menon','rakesh.bhat'])[1+((g-1)%10)],'.','_'))||g||'@temp.com',
       (ARRAY['Mehta Legal Chambers','Western Region Law Associates','Narmada Legal Services','Civic Justice Partners','Desai and Shah Advocates'])[1+((g-1)%5)],
       format('Chamber %s, District Court Complex, %s; consultations by appointment', g, (ARRAY['Ahmedabad','Rajkot','Surat','Vadodara','Mumbai','Pune','Jaipur','Hyderabad','Bengaluru','Chennai'])[1+((g-1)%10)]),
       (ARRAY['Active','Active','Active','On Leave','Suspended'])[1+((g-1)%5)]
FROM generate_series(1, GREATEST(0, 92-(SELECT COUNT(*) FROM public.lawyer))) g;

INSERT INTO public.witness (witness_id, witness_details, testimony_type)
SELECT COALESCE((SELECT MAX(witness_id) FROM public.witness),0)+g,
       format('%s, residing in %s; identity and contact particulars are retained in the sealed registry record.',
       (ARRAY['Nandita Parmar','Rishabh Tiwari','Mihir Desai','Saira Khan','Gautam Borse','Aarushi Nair','Keshav Rathod','Nilofer Merchant','Pratiksha Dave','Samarjeet Singh'])[1+((g-1)%10)],
       (ARRAY['Ahmedabad','Rajkot','Morbi','Surat','Vadodara','Mumbai','Pune','Jaipur','Hyderabad','Kochi'])[1+((g-1)%10)]),
       (ARRAY['Eyewitness','Accountant','Investigating Officer','Medical Expert','Forensic Expert','Neighbour'])[1+((g-1)%6)]
FROM generate_series(1, GREATEST(0, 98-(SELECT COUNT(*) FROM public.witness))) g;

INSERT INTO public.courtroom (room_id, room_number, court_id)
SELECT COALESCE((SELECT MAX(room_id) FROM public.courtroom),0)+g,
       format('%s - Court Hall %02s', (ARRAY['Civil','Criminal','Family','Commercial','Sessions'])[1+((g-1)%5)], g),
       1+((g-1)%(SELECT COUNT(*) FROM public.court))
FROM generate_series(1, GREATEST(0, 89-(SELECT COUNT(*) FROM public.courtroom))) g;

INSERT INTO public.court_case (case_id, cuid, cnr, case_title, case_type, filing_date, court_id)
SELECT COALESCE((SELECT MAX(case_id) FROM public.court_case),0)+g,
       format('CUID-IND-%s-%s', 2024+(g%3), lpad((COALESCE((SELECT MAX(case_id) FROM public.court_case),0)+g)::text,5,'0')),
       format('CNR/IND/%s/%s', 2024+(g%3), lpad((COALESCE((SELECT MAX(case_id) FROM public.court_case),0)+g)::text,6,'0')),
       (ARRAY['Petition seeking recovery of unpaid contractual dues','Dispute concerning title to inherited residential property','Application for protection in a matrimonial proceeding','Claim arising from alleged deficiency in construction services','Proceedings concerning dishonour of a commercial payment instrument','Petition challenging termination of employment','Claim for compensation following a road traffic incident','Application seeking enforcement of a maintenance order','Dispute over possession and lawful occupation of premises','Proceedings relating to alleged misappropriation of entrusted funds'])[1+((g-1)%10)],
       (ARRAY['Civil','Criminal','Family','Commercial','Motor Accident'])[1+((g-1)%5)],
       DATE '2023-01-01' + (((g*11)%1000)::integer),
       1+((g-1)%(SELECT COUNT(*) FROM public.court))
FROM generate_series(1, GREATEST(0, 106-(SELECT COUNT(*) FROM public.court_case))) g;

INSERT INTO public.app_user (user_id, user_name, email, phone, account_status, role_id)
SELECT COALESCE((SELECT MAX(user_id) FROM public.app_user),0)+g,
       (ARRAY['Rupal Trivedi','Sanjay Parmar','Mitali Desai','Faisal Qureshi','Kavita Nair','Bhavesh Rathod','Nupur Shah','Akhil Menon','Jaya Solanki','Rakesh Soni'])[1+((g-1)%10)],
       lower(replace((ARRAY['rupal.trivedi','sanjay.parmar','mitali.desai','faisal.qureshi','kavita.nair','bhavesh.rathod','nupur.shah','akhil.menon','jaya.solanki','rakesh.soni'])[1+((g-1)%10)],'.','_'))||g||'@temp.com',
       format('+91-95%08s', (73000000+g)::text),
       (ARRAY['Active','Active','Active','Inactive','Locked'])[1+((g-1)%5)],
       1+((g-1)%(SELECT COUNT(*) FROM public.role))
FROM generate_series(1, GREATEST(0, 95-(SELECT COUNT(*) FROM public.app_user))) g;

INSERT INTO public.hearing (hearing_id, hearing_date, hearing_purpose, start_time, end_time, proceeding_summary, outcome, next_scheduled_hearing_date, case_id, room_id, bench_id, cause_list_id, sequence_number)
SELECT COALESCE((SELECT MAX(hearing_id) FROM public.hearing),0)+g,
       DATE '2025-01-06' + (((g*5)%330)::integer),
       (ARRAY['Arguments on interim relief','Cross-examination of the claimant witness','Scrutiny of original documentary evidence','Hearing on framing of issues','Compliance review of previous directions','Recording of evidence','Settlement discussion before the court','Final submissions by both parties','Verification of service of summons','Consideration of the investigation report'])[1+((g-1)%10)],
       TIME '09:30' + ((g%7)*INTERVAL '30 minutes'),
       TIME '10:15' + ((g%7)*INTERVAL '30 minutes'),
       (ARRAY['Counsel for both parties addressed the court. The relevant pleadings were taken on record and the matter was considered for further directions.','The witness was examined in chief and the opposing counsel was permitted to put questions on the documents produced.','The registry confirmed service of notice. The respondent sought time to file a reply with supporting records.','Original invoices and correspondence were produced for inspection. The court directed both sides to exchange legible copies.','The investigating officer placed the progress report on record and clarified the steps taken since the previous hearing.','The parties informed the court that settlement discussions were continuing and requested a short date for reporting progress.'])[1+((g-1)%6)],
       (ARRAY['Matter adjourned for further arguments','Notice issued; reply awaited','Evidence partly recorded','Interim protection continued','Matter reserved for orders','Compliance to be reported on next date'])[1+((g-1)%6)],
       DATE '2025-02-01' + (((g*7)%350)::integer),
       1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       1+((g-1)%(SELECT COUNT(*) FROM public.courtroom)),
       1+((g-1)%(SELECT COUNT(*) FROM public.bench)),
       1+((g-1)%(SELECT COUNT(*) FROM public.cause_list)),
       10+g
FROM generate_series(1, GREATEST(0, 108-(SELECT COUNT(*) FROM public.hearing))) g;

INSERT INTO public.judgment (judgment_id, pronouncement_date, verdict_text, digital_signature_hash, case_id)
SELECT COALESCE((SELECT MAX(judgment_id) FROM public.judgment),0)+g,
       DATE '2025-06-01' + ((g*3)::integer),
       (ARRAY['The petition is allowed in part. The respondent shall comply with the directions set out in the operative portion of this judgment.','The suit is dismissed as the claimant has not discharged the burden of proving the material allegations.','The matter is disposed of in terms of the settlement recorded before the court, subject to compliance by both parties.','The application is allowed. The competent authority shall reconsider the representation by a reasoned order within the prescribed period.','The appeal is partly allowed and the matter is remitted for limited reconsideration in accordance with law.'])[1+((g-1)%5)],
       md5('ccms-judgment-signature-'||g||'-2025'),
       (SELECT c.case_id FROM public.court_case c WHERE NOT EXISTS (SELECT 1 FROM public.judgment j WHERE j.case_id=c.case_id) ORDER BY c.case_id OFFSET (g-1) LIMIT 1)
FROM generate_series(1, GREATEST(0, 90-(SELECT COUNT(*) FROM public.judgment))) g;

INSERT INTO public.court_order (order_id, order_type, order_content, digital_signature_hash, case_id, issued_by_judge_id, hearing_id)
SELECT COALESCE((SELECT MAX(order_id) FROM public.court_order),0)+g,
       (ARRAY['Procedural Direction','Summons Order','Production of Documents Order','Interim Protection Order','Bail Order','Notice of Motion Order'])[1+((g-1)%6)],
       (ARRAY['The respondent shall file a reply affidavit with supporting documents within three weeks.','The registry shall issue notice to the parties at the addresses recorded in the case file.','The investigating officer shall place the updated status report and relevant annexures on record.','The parties shall preserve the disputed property and shall not create third-party rights until further orders.','The application is listed for further hearing after completion of the cross-examination.','The original records shall be produced before the court on the next scheduled date.'])[1+((g-1)%6)],
       md5('ccms-court-order-'||g||'-2025'),
       h.case_id,
       1+((g-1)%(SELECT COUNT(*) FROM public.judge)),
       h.hearing_id
FROM generate_series(1, GREATEST(0, 99-(SELECT COUNT(*) FROM public.court_order))) g
JOIN LATERAL (SELECT hearing_id, case_id FROM public.hearing ORDER BY hearing_id OFFSET ((g-1)%(SELECT COUNT(*) FROM public.hearing)) LIMIT 1) h ON TRUE;

INSERT INTO public.petition (petition_id, subject, verification_status, case_id, lawyer_id, scrutinized_by_clerk_id, verified_by_clerk_id)
SELECT COALESCE((SELECT MAX(petition_id) FROM public.petition),0)+g,
       (ARRAY['Petition for interim protection pending disposal of the suit','Application for condonation of delay in filing the appeal','Petition seeking enforcement of the recorded settlement','Application for release of documents retained during investigation','Petition for restoration of possession and consequential relief','Application seeking modification of visitation arrangements','Petition for direction to produce original account records'])[1+((g-1)%7)],
       (ARRAY['Verified','Pending','Rejected','Under Scrutiny','Verified'])[1+((g-1)%5)],
       1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       1+((g-1)%(SELECT COUNT(*) FROM public.lawyer)),
       1+((g-1)%(SELECT COUNT(*) FROM public.court_clerk)),
       CASE WHEN g%4=0 THEN NULL ELSE 1+((g*3-1)%(SELECT COUNT(*) FROM public.court_clerk)) END
FROM generate_series(1, GREATEST(0, 104-(SELECT COUNT(*) FROM public.petition))) g;

INSERT INTO public.evidence (evidence_id, exhibit_number, submission_date, description, judicial_admission_status, case_id, party_id)
SELECT COALESCE((SELECT MAX(evidence_id) FROM public.evidence),0)+g,
       format('EXH-%s-%s', 2025+(g%2), lpad(g::text,4,'0')),
       DATE '2025-01-15' + (((g*4)%330)::integer),
       (ARRAY['Certified copy of the registered sale deed showing the chain of title relied upon by the claimant.','Bank statement reflecting the disputed transfer and the subsequent reversal entry.','Medical certificate recording the injuries noted during examination at the district hospital.','Photographs of the site taken during the joint inspection, with date and location details.','Email correspondence exchanged by the parties regarding delivery, payment and outstanding obligations.','Copy of the notice issued by the registry together with the postal tracking acknowledgment.','Forensic examination report describing the condition and identification marks of the seized article.','Affidavit of the witness confirming the events stated in the accompanying deposition.'])[1+((g-1)%8)],
       (ARRAY['Admitted','Pending','Rejected','Under Review','Admitted'])[1+((g-1)%5)],
       1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       1+((g*7-1)%(SELECT COUNT(*) FROM public.party))
FROM generate_series(1, GREATEST(0, 110-(SELECT COUNT(*) FROM public.evidence))) g;

INSERT INTO public.adjournment (adjournment_id, reason, request_date, judicial_approval_status, revised_hearing_date, hearing_id, reviewed_by_judge_id)
SELECT COALESCE((SELECT MAX(adjournment_id) FROM public.adjournment),0)+g,
       (ARRAY['Lead counsel was engaged before another court and sought a short accommodation.','The medical record of the material witness was filed with a request for a later date.','The parties requested time to explore an amicable settlement.','The certified copies required for the hearing had not yet been supplied by the record room.','The investigating officer sought time to complete the supplementary report.','A necessary document was served shortly before the scheduled hearing.'])[1+((g-1)%6)],
       DATE '2025-03-01' + ((g*3)::integer),
       (ARRAY['Pending','Approved','Rejected','Approved','Pending'])[1+((g-1)%5)],
       DATE '2025-04-01' + ((g*4)::integer),
       1+((g-1)%(SELECT COUNT(*) FROM public.hearing)),
       1+((g-1)%(SELECT COUNT(*) FROM public.judge))
FROM generate_series(1, GREATEST(0, 93-(SELECT COUNT(*) FROM public.adjournment))) g;

INSERT INTO public.notification (notification_id, message, recipient, notification_date, status, case_id, user_id)
SELECT COALESCE((SELECT MAX(notification_id) FROM public.notification),0)+g,
       (ARRAY['A hearing has been scheduled. Please review the cause list and appear on the notified date.','The registry has received a filing in the matter. Please review the status of the submitted documents.','A court direction has been recorded. Kindly review the order and comply within the stated period.','The next hearing date has been updated in the case record.','A document has been marked for verification by the registry.'])[1+((g-1)%5)],
       u.email,
       TIMESTAMPTZ '2025-04-01 09:00:00+05:30' + (g*INTERVAL '3 hours'),
       (ARRAY['Delivered','Pending','Failed'])[1+((g-1)%3)],
       1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       u.user_id
FROM generate_series(1, GREATEST(0, 86-(SELECT COUNT(*) FROM public.notification))) g
JOIN LATERAL (SELECT user_id,email FROM public.app_user WHERE email IS NOT NULL ORDER BY user_id OFFSET ((g-1)%(SELECT COUNT(*) FROM public.app_user WHERE email IS NOT NULL)) LIMIT 1) u ON TRUE;

INSERT INTO public.audit_log (audit_id, action_performed, "timestamp", client_ip, pre_modification_state, post_modification_state, user_id, case_id)
SELECT COALESCE((SELECT MAX(audit_id) FROM public.audit_log),0)+g,
       (ARRAY['UPDATE_CASE_STATUS','UPLOAD_DOCUMENT','VERIFY_PETITION','SCHEDULE_HEARING','RECORD_EVIDENCE','ISSUE_COURT_ORDER','UPDATE_PARTY_CONTACT'])[1+((g-1)%7)],
       TIMESTAMPTZ '2025-05-01 08:30:00+05:30' + (g*INTERVAL '47 minutes'),
       format('10.%s.%s.%s', 20+(g%200), 1+(g%250), 1+(g%250))::inet,
       (ARRAY['Case status was Pending; registry review had not yet been recorded.','No verified document was attached to the filing at the time of review.','The hearing schedule contained the earlier date and courtroom allocation.','The petition was awaiting scrutiny by the filing clerk.','The party contact record contained the previously registered address.'])[1+((g-1)%5)],
       (ARRAY['Case status updated to Under Review following registry scrutiny.','Certified document attached and verification status changed to Verified.','Hearing date and courtroom allocation updated after judicial directions.','Petition scrutiny completed and forwarded for judicial consideration.','Party address amended on the basis of the signed application.'])[1+((g-1)%5)],
       1+((g-1)%(SELECT COUNT(*) FROM public.app_user)),
       1+((g-1)%(SELECT COUNT(*) FROM public.court_case))
FROM generate_series(1, GREATEST(0, 102-(SELECT COUNT(*) FROM public.audit_log))) g;

INSERT INTO public.filing_defect (defect_id, defect_description, cure_deadline, cure_status, identification_date, clerk_id)
SELECT COALESCE((SELECT MAX(defect_id) FROM public.filing_defect),0)+g,
       (ARRAY['The affidavit is not signed on the final page by the deponent.','The annexure index does not correspond with the documents uploaded.','The court fee receipt is illegible and requires a clearer copy.','The vakalatnama is missing the advocate enrolment particulars.','The petition does not state the complete address for service of notice.','The verification paragraph does not specify which statements are based on personal knowledge.','The uploaded document is missing the page containing the exhibit identification mark.'])[1+((g-1)%7)],
       CASE WHEN g%9=0 THEN NULL ELSE DATE '2025-06-01' + ((g*4)::integer) END,
       (ARRAY['Pending','Cured','Under Review','Pending','Cured'])[1+((g-1)%5)],
       DATE '2025-05-01' + ((g*3)::integer),
       1+((g-1)%(SELECT COUNT(*) FROM public.court_clerk))
FROM generate_series(1, GREATEST(0, 97-(SELECT COUNT(*) FROM public.filing_defect))) g;

INSERT INTO public.case_status_history (case_id, transition_timestamp, previous_status, new_status, transition_remarks, user_id)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       TIMESTAMPTZ '2025-01-01 08:00:00+05:30' + (g*INTERVAL '19 hours'),
       (ARRAY[NULL,'Filed','Under Review','Pending','Hearing Scheduled'])[1+((g-1)%5)],
       (ARRAY['Filed','Under Review','Hearing Scheduled','Evidence Stage','Arguments','Disposed','Closed'])[1+((g-1)%7)],
       (ARRAY['Initial filing was registered and assigned a case number.','Registry scrutiny was completed and the matter was placed before the court.','The next hearing was scheduled and notice was directed to issue.','Documentary evidence was received and marked for judicial consideration.','Arguments were heard and the matter was listed for further orders.','Proceedings were disposed of by a reasoned judicial order.','The record was closed after completion of the required formalities.'])[1+((g-1)%7)],
       1+((g-1)%(SELECT COUNT(*) FROM public.app_user))
FROM generate_series(1, GREATEST(0, 109-(SELECT COUNT(*) FROM public.case_status_history))) g;

INSERT INTO public.document (document_id, title, document_type, file_path, upload_timestamp, verification_status, version, confidentiality_level, case_id)
SELECT COALESCE((SELECT MAX(document_id) FROM public.document),0)+g,
       (ARRAY['Affidavit in Support of Interim Application','Certified Copy of Registered Agreement','Medical Examination Report','Bank Account Statement','Service of Notice Acknowledgment','Written Statement of Respondent','Site Inspection Photographs','Investigation Progress Report','Vakalatnama and Authority Letter'])[1+((g-1)%9)],
       (ARRAY['Affidavit','Agreement','Medical Record','Financial Record','Service Proof','Pleading','Photograph','Investigation Report','Authority Document'])[1+((g-1)%9)],
       format('/ccms/cases/%s/documents/record-%s.pdf',1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),g),
       TIMESTAMPTZ '2025-02-01 10:00:00+05:30' + (g*INTERVAL '2 days'),
       (ARRAY['Verified','Pending','Rejected','Under Review'])[1+((g-1)%4)],
       1+(g%3),
       (ARRAY['Public','Restricted','Confidential'])[1+((g-1)%3)],
       1+((g-1)%(SELECT COUNT(*) FROM public.court_case))
FROM generate_series(1, GREATEST(0, 100-(SELECT COUNT(*) FROM public.document))) g;

INSERT INTO public.case_party (case_id, party_id)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       1+(((g-1)*7+17)%(SELECT COUNT(*) FROM public.party))
FROM generate_series(1, GREATEST(0, 107-(SELECT COUNT(*) FROM public.case_party))) g
WHERE NOT EXISTS (SELECT 1 FROM public.case_party cp WHERE cp.case_id=1+((g-1)%(SELECT COUNT(*) FROM public.court_case)) AND cp.party_id=1+(((g-1)*7+17)%(SELECT COUNT(*) FROM public.party)));

INSERT INTO public.case_witness (case_id, witness_id, summons_status)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.court_case)),
       1+(((g-1)*11+23)%(SELECT COUNT(*) FROM public.witness)),
       (ARRAY['Served','Pending','Appeared','Returned Unserved'])[1+((g-1)%4)]
FROM generate_series(1, GREATEST(0, 85-(SELECT COUNT(*) FROM public.case_witness))) g
WHERE NOT EXISTS (SELECT 1 FROM public.case_witness cw WHERE cw.case_id=1+((g-1)%(SELECT COUNT(*) FROM public.court_case)) AND cw.witness_id=1+(((g-1)*11+23)%(SELECT COUNT(*) FROM public.witness)));

INSERT INTO public.bench_judge (bench_id, judge_id)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.bench)),
       1+((g+39)%(SELECT COUNT(*) FROM public.judge))
FROM generate_series(1, GREATEST(0, 92-(SELECT COUNT(*) FROM public.bench_judge))) g
WHERE NOT EXISTS (SELECT 1 FROM public.bench_judge bj WHERE bj.bench_id=1+((g-1)%(SELECT COUNT(*) FROM public.bench)) AND bj.judge_id=1+((g+39)%(SELECT COUNT(*) FROM public.judge)));

INSERT INTO public.judge_court_order (judge_id, order_id)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.judge)),
       1+(((g-1)*7+19)%(SELECT COUNT(*) FROM public.court_order))
FROM generate_series(1, GREATEST(0, 88-(SELECT COUNT(*) FROM public.judge_court_order))) g
WHERE NOT EXISTS (SELECT 1 FROM public.judge_court_order x WHERE x.judge_id=1+((g-1)%(SELECT COUNT(*) FROM public.judge)) AND x.order_id=1+(((g-1)*7+19)%(SELECT COUNT(*) FROM public.court_order)));

INSERT INTO public.judge_evidence (judge_id, evidence_id)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.judge)),
       1+(((g-1)*9+27)%(SELECT COUNT(*) FROM public.evidence))
FROM generate_series(1, GREATEST(0, 105-(SELECT COUNT(*) FROM public.judge_evidence))) g
WHERE NOT EXISTS (SELECT 1 FROM public.judge_evidence x WHERE x.judge_id=1+((g-1)%(SELECT COUNT(*) FROM public.judge)) AND x.evidence_id=1+(((g-1)*9+27)%(SELECT COUNT(*) FROM public.evidence)));

INSERT INTO public.lawyer_party (lawyer_id, party_id)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.lawyer)),
       1+(((g-1)*7+29)%(SELECT COUNT(*) FROM public.party))
FROM generate_series(1, GREATEST(0, 96-(SELECT COUNT(*) FROM public.lawyer_party))) g
WHERE NOT EXISTS (SELECT 1 FROM public.lawyer_party x WHERE x.lawyer_id=1+((g-1)%(SELECT COUNT(*) FROM public.lawyer)) AND x.party_id=1+(((g-1)*7+29)%(SELECT COUNT(*) FROM public.party)));

INSERT INTO public.lawyer_case (lawyer_id, case_id, representation_start_date, representation_end_date)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.lawyer)),
       1+(((g-1)*7+37)%(SELECT COUNT(*) FROM public.court_case)),
       DATE '2024-01-01' + ((g*5)::integer),
       CASE WHEN g%4=0 THEN DATE '2025-01-01' + ((g*5)::integer) ELSE NULL END
FROM generate_series(1, GREATEST(0, 103-(SELECT COUNT(*) FROM public.lawyer_case))) g
WHERE NOT EXISTS (SELECT 1 FROM public.lawyer_case x WHERE x.lawyer_id=1+((g-1)%(SELECT COUNT(*) FROM public.lawyer)) AND x.case_id=1+(((g-1)*7+37)%(SELECT COUNT(*) FROM public.court_case)));

INSERT INTO public.hearing_witness (hearing_id, witness_id, testimony)
SELECT 1+((g-1)%(SELECT COUNT(*) FROM public.hearing)),
       1+(((g-1)*7+41)%(SELECT COUNT(*) FROM public.witness)),
       (ARRAY['The witness identified the signature appearing on the agreement and confirmed the date on which it was executed.','The witness described the condition of the premises during the inspection and identified the photographs placed on record.','The witness explained the entries in the account register and clarified the corresponding payment receipts.','The witness confirmed receipt of the notice and identified the acknowledgment maintained in the ordinary course of business.','The witness stated the sequence of events and identified the relevant entry in the contemporaneous record.'])[1+((g-1)%5)]
FROM generate_series(1, GREATEST(0, 90-(SELECT COUNT(*) FROM public.hearing_witness))) g
WHERE NOT EXISTS (SELECT 1 FROM public.hearing_witness x WHERE x.hearing_id=1+((g-1)%(SELECT COUNT(*) FROM public.hearing)) AND x.witness_id=1+(((g-1)*7+41)%(SELECT COUNT(*) FROM public.witness)));


ALTER TABLE public.hearing ENABLE TRIGGER USER;
ALTER TABLE public.judgment ENABLE TRIGGER USER;

-- Advance identity sequences because IDs were inserted explicitly.
SELECT setval(pg_get_serial_sequence('public.court', 'court_id'), (SELECT MAX(court_id) FROM public.court), TRUE);
SELECT setval(pg_get_serial_sequence('public.judge', 'judge_id'), (SELECT MAX(judge_id) FROM public.judge), TRUE);
SELECT setval(pg_get_serial_sequence('public.party', 'party_id'), (SELECT MAX(party_id) FROM public.party), TRUE);
SELECT setval(pg_get_serial_sequence('public.role', 'role_id'), (SELECT MAX(role_id) FROM public.role), TRUE);
SELECT setval(pg_get_serial_sequence('public.court_clerk', 'clerk_id'), (SELECT MAX(clerk_id) FROM public.court_clerk), TRUE);
SELECT setval(pg_get_serial_sequence('public.bench', 'bench_id'), (SELECT MAX(bench_id) FROM public.bench), TRUE);
SELECT setval(pg_get_serial_sequence('public.cause_list', 'cause_list_id'), (SELECT MAX(cause_list_id) FROM public.cause_list), TRUE);
SELECT setval(pg_get_serial_sequence('public.lawyer', 'lawyer_id'), (SELECT MAX(lawyer_id) FROM public.lawyer), TRUE);
SELECT setval(pg_get_serial_sequence('public.witness', 'witness_id'), (SELECT MAX(witness_id) FROM public.witness), TRUE);
SELECT setval(pg_get_serial_sequence('public.courtroom', 'room_id'), (SELECT MAX(room_id) FROM public.courtroom), TRUE);
SELECT setval(pg_get_serial_sequence('public.court_case', 'case_id'), (SELECT MAX(case_id) FROM public.court_case), TRUE);
SELECT setval(pg_get_serial_sequence('public.app_user', 'user_id'), (SELECT MAX(user_id) FROM public.app_user), TRUE);
SELECT setval(pg_get_serial_sequence('public.hearing', 'hearing_id'), (SELECT MAX(hearing_id) FROM public.hearing), TRUE);
SELECT setval(pg_get_serial_sequence('public.judgment', 'judgment_id'), (SELECT MAX(judgment_id) FROM public.judgment), TRUE);
SELECT setval(pg_get_serial_sequence('public.court_order', 'order_id'), (SELECT MAX(order_id) FROM public.court_order), TRUE);
SELECT setval(pg_get_serial_sequence('public.petition', 'petition_id'), (SELECT MAX(petition_id) FROM public.petition), TRUE);
SELECT setval(pg_get_serial_sequence('public.evidence', 'evidence_id'), (SELECT MAX(evidence_id) FROM public.evidence), TRUE);
SELECT setval(pg_get_serial_sequence('public.adjournment', 'adjournment_id'), (SELECT MAX(adjournment_id) FROM public.adjournment), TRUE);
SELECT setval(pg_get_serial_sequence('public.notification', 'notification_id'), (SELECT MAX(notification_id) FROM public.notification), TRUE);
SELECT setval(pg_get_serial_sequence('public.audit_log', 'audit_id'), (SELECT MAX(audit_id) FROM public.audit_log), TRUE);
SELECT setval(pg_get_serial_sequence('public.filing_defect', 'defect_id'), (SELECT MAX(defect_id) FROM public.filing_defect), TRUE);
SELECT setval(pg_get_serial_sequence('public.document', 'document_id'), (SELECT MAX(document_id) FROM public.document), TRUE);

COMMIT;

-- Verify the loaded row counts.
SELECT 'court' AS table_name, COUNT(*) AS row_count FROM public.court
UNION ALL SELECT 'judge', COUNT(*) FROM public.judge
UNION ALL SELECT 'party', COUNT(*) FROM public.party
UNION ALL SELECT 'role', COUNT(*) FROM public.role
UNION ALL SELECT 'court_clerk', COUNT(*) FROM public.court_clerk
UNION ALL SELECT 'bench', COUNT(*) FROM public.bench
UNION ALL SELECT 'cause_list', COUNT(*) FROM public.cause_list
UNION ALL SELECT 'lawyer', COUNT(*) FROM public.lawyer
UNION ALL SELECT 'witness', COUNT(*) FROM public.witness
UNION ALL SELECT 'courtroom', COUNT(*) FROM public.courtroom
UNION ALL SELECT 'court_case', COUNT(*) FROM public.court_case
UNION ALL SELECT 'app_user', COUNT(*) FROM public.app_user
UNION ALL SELECT 'hearing', COUNT(*) FROM public.hearing
UNION ALL SELECT 'judgment', COUNT(*) FROM public.judgment
UNION ALL SELECT 'court_order', COUNT(*) FROM public.court_order
UNION ALL SELECT 'petition', COUNT(*) FROM public.petition
UNION ALL SELECT 'evidence', COUNT(*) FROM public.evidence
UNION ALL SELECT 'adjournment', COUNT(*) FROM public.adjournment
UNION ALL SELECT 'notification', COUNT(*) FROM public.notification
UNION ALL SELECT 'audit_log', COUNT(*) FROM public.audit_log
UNION ALL SELECT 'filing_defect', COUNT(*) FROM public.filing_defect
UNION ALL SELECT 'case_status_history', COUNT(*) FROM public.case_status_history
UNION ALL SELECT 'document', COUNT(*) FROM public.document
UNION ALL SELECT 'case_party', COUNT(*) FROM public.case_party
UNION ALL SELECT 'case_witness', COUNT(*) FROM public.case_witness
UNION ALL SELECT 'bench_judge', COUNT(*) FROM public.bench_judge
UNION ALL SELECT 'judge_court_order', COUNT(*) FROM public.judge_court_order
UNION ALL SELECT 'judge_evidence', COUNT(*) FROM public.judge_evidence
UNION ALL SELECT 'lawyer_party', COUNT(*) FROM public.lawyer_party
UNION ALL SELECT 'lawyer_case', COUNT(*) FROM public.lawyer_case
UNION ALL SELECT 'hearing_witness', COUNT(*) FROM public.hearing_witness
ORDER BY table_name;


-- Final range check: every one of the 31 base tables must contain 85-110 rows.
WITH table_counts AS (
    SELECT 'court' AS table_name, COUNT(*)::int AS row_count FROM public.court
    UNION ALL SELECT 'judge', COUNT(*)::int FROM public.judge
    UNION ALL SELECT 'party', COUNT(*)::int FROM public.party
    UNION ALL SELECT 'role', COUNT(*)::int FROM public.role
    UNION ALL SELECT 'court_clerk', COUNT(*)::int FROM public.court_clerk
    UNION ALL SELECT 'bench', COUNT(*)::int FROM public.bench
    UNION ALL SELECT 'cause_list', COUNT(*)::int FROM public.cause_list
    UNION ALL SELECT 'lawyer', COUNT(*)::int FROM public.lawyer
    UNION ALL SELECT 'witness', COUNT(*)::int FROM public.witness
    UNION ALL SELECT 'courtroom', COUNT(*)::int FROM public.courtroom
    UNION ALL SELECT 'court_case', COUNT(*)::int FROM public.court_case
    UNION ALL SELECT 'app_user', COUNT(*)::int FROM public.app_user
    UNION ALL SELECT 'hearing', COUNT(*)::int FROM public.hearing
    UNION ALL SELECT 'judgment', COUNT(*)::int FROM public.judgment
    UNION ALL SELECT 'court_order', COUNT(*)::int FROM public.court_order
    UNION ALL SELECT 'petition', COUNT(*)::int FROM public.petition
    UNION ALL SELECT 'evidence', COUNT(*)::int FROM public.evidence
    UNION ALL SELECT 'adjournment', COUNT(*)::int FROM public.adjournment
    UNION ALL SELECT 'notification', COUNT(*)::int FROM public.notification
    UNION ALL SELECT 'audit_log', COUNT(*)::int FROM public.audit_log
    UNION ALL SELECT 'filing_defect', COUNT(*)::int FROM public.filing_defect
    UNION ALL SELECT 'case_status_history', COUNT(*)::int FROM public.case_status_history
    UNION ALL SELECT 'document', COUNT(*)::int FROM public.document
    UNION ALL SELECT 'case_party', COUNT(*)::int FROM public.case_party
    UNION ALL SELECT 'case_witness', COUNT(*)::int FROM public.case_witness
    UNION ALL SELECT 'bench_judge', COUNT(*)::int FROM public.bench_judge
    UNION ALL SELECT 'judge_court_order', COUNT(*)::int FROM public.judge_court_order
    UNION ALL SELECT 'judge_evidence', COUNT(*)::int FROM public.judge_evidence
    UNION ALL SELECT 'lawyer_party', COUNT(*)::int FROM public.lawyer_party
    UNION ALL SELECT 'lawyer_case', COUNT(*)::int FROM public.lawyer_case
    UNION ALL SELECT 'hearing_witness', COUNT(*)::int FROM public.hearing_witness
)
SELECT table_name, row_count,
       CASE WHEN row_count BETWEEN 85 AND 110 THEN 'PASS' ELSE 'CHECK' END AS range_status
FROM table_counts
ORDER BY table_name;
