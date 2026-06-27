

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const express = require('express');
const nodemailer = require('nodemailer');
const bodyParser = require('body-parser');
const cors = require('cors');
const mysql = require('mysql2');
const imap = require('imap-simple');
require('dotenv').config();
const { htmlToText } = require('html-to-text');

const app = express();
const PORT = 3002;

// Middleware to parse JSON and handle CORS
app.use(cors());
app.use(bodyParser.json());

// MySQL Database configuration
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'Admin@57', // Your MySQL password (if any)
    database: 'email'
});

// Connect to the MySQL database
db.connect((err) => {
    if (err) {
        console.error('Error connecting to MySQL:', err.message);
    } else {
        console.log('Connected to MySQL database.');
    }
});

// Configure Nodemailer transporter
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

// Route to send email and store it in the database
app.post('/send-email', (req, res) => {
    const { to, subject, text } = req.body;

    if (!to || !subject || !text) {
        return res.status(400).json({ message: 'Missing required fields (to, subject, or text).' });
    }

    const mailOptions = {
        from: process.env.EMAIL_USER,
        to,
        subject,
        text,
    };

    transporter.sendMail(mailOptions, (error, info) => {
        if (error) {
            console.error('Error sending email:', error);
            return res.status(500).json({ message: 'Failed to send email', error });
        }

        const sql = `INSERT INTO sent_emails (recipient, subject, body) VALUES (?, ?, ?)`;
        db.query(sql, [to, subject, text], (err, result) => {
            if (err) {
                console.error('Error saving email to database:', err);
                return res.status(500).json({ message: 'Email sent but failed to save to database', error: err });
            } else {
                console.log('Email saved to database, ID:', result.insertId);
                return res.status(200).json({ message: 'Email sent and saved successfully', info });
            }
        });
    });
});

// Route to get all sent emails
app.get('/sent-emails', (req, res) => {
    const sql = 'SELECT * FROM sent_emails ORDER BY timestamp DESC';
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Error retrieving sent emails:', err);
            return res.status(500).json({ message: 'Failed to retrieve sent emails', error: err });
        } else {
            return res.status(200).json(results);
        }
    });
});

app.post('/save-email', async(req, res) => {
    const { subject, body, sender } = req.body;

    try {
        const result = await db.query(
            'INSERT INTO emails (subject, body, sender) VALUES (?, ?, ?)', [subject, body, sender]
        );
        res.status(200).json({ message: 'Email stored successfully' });
    } catch (error) {
        console.error('Error saving email:', error);
        res.status(500).json({ error: 'Failed to store email' });
    }
});


// Route to get all received emails
// Updated example for the endpoint to retrieve emails
app.get('/inbox-emails', async(req, res) => {
    try {
        const [rows] = await db.promise().query('SELECT * FROM inbox_emails ORDER BY timestamp DESC');
        res.status(200).json(rows); // Only returning the rows array
    } catch (error) {
        console.error('Error fetching emails:', error);
        res.status(500).json({ error: 'Failed to load inbox emails' });
    }
});

// Route to get all emails
app.get('/all-mails', async (req, res) => {
    try {
        const [sent] = await db.promise().query(`
            SELECT recipient AS contact,
                   subject,
                   body,
                   timestamp,
                   'sent' AS type
            FROM sent_emails
        `);

        const [inbox] = await db.promise().query(`
            SELECT sender AS contact,
                   subject,
                   body,
                   timestamp,
                   'received' AS type
            FROM inbox_emails
        `);

        const allEmails = [...sent, ...inbox];

        allEmails.sort(
            (a, b) => new Date(b.timestamp) - new Date(a.timestamp)
        );

        res.json(allEmails);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to load emails' });
    }
});



// IMAP Configuration for receiving emails
const imapConfig = {
    imap: {
        user: process.env.EMAIL_USER,
        password: process.env.EMAIL_PASS,
        host: 'imap.gmail.com',
        port: 993,
        tls: true,
        connTimeout: 10000, // Increased timeout
        authTimeout: 10000, // Increased authentication timeout
    }
};

imap.connect(imapConfig)
    .then(connection => {
        console.log('Connected to IMAP server');
        // Proceed with fetching emails
    })
    .catch(error => {
        console.error('Error checking emails:', error);
    });

// Function to check for incoming emails
const checkEmails = async () => {
    try {
        const connection = await imap.connect(imapConfig);

        await connection.openBox('INBOX');

        const searchCriteria = ['UNSEEN'];

        const fetchOptions = {
            bodies: [
                'HEADER.FIELDS (FROM TO SUBJECT DATE)',
                'TEXT'
            ],
            markSeen: true
        };

        const messages = await connection.search(
            searchCriteria,
            fetchOptions
        );

        console.log(`Found ${messages.length} unread emails`);

        messages.forEach((message) => {

            console.log("MESSAGE PARTS:", message.parts);

            const header = message.parts.find(
                part =>
                    part.which ===
                    'HEADER.FIELDS (FROM TO SUBJECT DATE)'
            )?.body;

            let textBody = '';

            message.parts.forEach((part) => {
                if (part.which === 'TEXT') {
                    textBody = part.body || '';
                }
                console.log("TEXT BODY START");
console.log(textBody.substring(0, 1000));
console.log("TEXT BODY END");
            });


           let body = textBody || 'No content available';

// Extract only plain text content
const plainTextMatch = body.match(
    /Content-Type:\s*text\/plain[\s\S]*?\r\n\r\n([\s\S]*?)\r\n--/i
);

if (plainTextMatch && plainTextMatch[1]) {
    body = plainTextMatch[1].trim();
} else {
    body = htmlToText(body, {
        wordwrap: 130
    });
}

console.log("CLEAN BODY:");
console.log(body);

            const from =
                header?.from?.[0] || 'Unknown';

            const subject =
                header?.subject?.[0] || 'No Subject';

            const date =
                header?.date?.[0]
                    ? new Date(header.date[0])
                    : new Date();

            const sql = `
                INSERT INTO inbox_emails
                (sender, subject, body, timestamp, starred, is_read)
                VALUES (?, ?, ?, ?, 0, 0)
            `;

            db.query(
                sql,
                [from, subject, body, date],
                (err) => {
                    if (err) {
                        console.error(
                            'Error saving incoming email:',
                            err
                        );
                    } else {
                        console.log(
                            'Incoming email saved to database'
                        );
                    }
                }
            );
        });

        connection.end();

    } catch (error) {

        console.error(
            'Error checking emails:',
            error
        );

    }
};


// const checkEmails = async() => {
//     try {
//         const connection = await imap.connect(imapConfig);
//         await connection.openBox('INBOX');

//         const searchCriteria = ['UNSEEN'];
//         const fetchOptions = { bodies: ['HEADER.FIELDS (FROM TO SUBJECT DATE)', 'TEXT'], markSeen: true };

//         const messages = await connection.search(searchCriteria, fetchOptions);

//         messages.forEach((message) => {
//             console.log("Message parts:", message.parts); // Log the entire message object

//             const header = message.parts.find(part => part.which === 'HEADER.FIELDS (FROM TO SUBJECT DATE)').body;

//             // Find the plain text or HTML body
//             let textBody = '';
//             let htmlBody = '';

//             message.parts.forEach(part => {
//                 if (part.which === 'TEXT') {
//                     textBody = part.body;
//                 }
//                 if (part.which === 'HTML') {
//                     htmlBody = part.body;
//                 }
//             });

//             // Fallback to text if HTML is not available
//             const rawBody = htmlBody || textBody || 'No content available';

//             const body = htmlToText(rawBody, {
//                   wordwrap: false
//             });

//             const from = header.from ? header.from[0] : 'Unknown';
//             const subject = header.subject ? header.subject[0] : 'No Subject';
//             const date = header.date ? new Date(header.date[0]) : new Date();

//             // Save the email to the database
//             const sql = `INSERT INTO inbox_emails (sender, subject, body, timestamp) VALUES (?, ?, ?, ?)`;
//             db.query(sql, [from, subject, body, date], (err) => {
//                 if (err) {
//                     console.error('Error saving incoming email:', err);
//                 } else {
//                     console.log('Incoming email saved to database');
//                 }
//             });
//         });

//         connection.end();
//     } catch (error) {
//         console.error('Error checking emails:', error);
//     }
// };

//star an email
app.post('/star-email', async (req, res) => {
    const { id } = req.body;

    try {
        await db.promise().query(
            'UPDATE inbox_emails SET starred = 1 WHERE id = ?',
            [id]
        );

        res.json({
            success: true,
            message: 'Email starred successfully'
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({
            error: 'Failed to star email'
        });
    }
});

//Get starred email
app.get('/starred-emails', async (req, res) => {
    try {

        const [rows] = await db.promise().query(`
            SELECT *
            FROM inbox_emails
            WHERE starred = 1
            ORDER BY timestamp DESC
        `);

        res.json(rows);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            error: 'Failed to load starred emails'
        });

    }
});

//Get unread emails
app.get('/unread-emails', async (req, res) => {
    try {

        const [rows] = await db.promise().query(`
            SELECT
                id,
                sender,
                subject,
                body,
                timestamp,
                starred,
                is_read
            FROM inbox_emails
            WHERE is_read = 0
            ORDER BY timestamp DESC
        `);

        res.json(rows);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            error: 'Failed to fetch unread emails'
        });

    }
});
//Mark email as read
app.post('/mark-read', async (req, res) => {

    const { id } = req.body;

    try {

        await db.promise().query(
            'UPDATE inbox_emails SET is_read = 1 WHERE id = ?',
            [id]
        );

        res.json({
            success: true
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            error: 'Failed to mark email as read'
        });

    }
});
// Check emails every 60 seconds
setInterval(checkEmails, 60000);

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});