const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10
});

const emailVerificationCodes = new Map();
const verifiedEmails = new Map();
const emailCodeCooldown = new Map();

function createVerificationCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function isValidEmail(email) {
  return /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/.test(String(email || '').trim());
}

async function findOrCreateLookup(connection, tableName, idColumn, nameColumn, rawName) {
  const name = String(rawName || '').trim();
  const [rows] = await connection.query(
    `SELECT ${idColumn} AS id FROM ${tableName} WHERE ${nameColumn} = ? LIMIT 1`,
    [name]
  );

  if (rows.length) {
    return rows[0].id;
  }

  const [result] = await connection.query(
    `INSERT INTO ${tableName} (${nameColumn}) VALUES (?)`,
    [name]
  );
  return result.insertId;
}

function parseDogWeight(rawWeight) {
  const value = String(rawWeight || '').match(/\d+(\.\d+)?/);
  if (!value) {
    return null;
  }
  return Number(value[0]);
}

async function ensureReviewColumns() {
  const [buySeqColumns] = await pool.query(
    `SELECT COLUMN_NAME
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'review'
       AND COLUMN_NAME = 'buy_seq'`
  );

  if (!buySeqColumns.length) {
    await pool.query('ALTER TABLE review ADD COLUMN buy_seq INT NULL');
    await pool.query('CREATE INDEX idx_review_buy_seq ON review (buy_seq)');
  }

  const [likeColumns] = await pool.query(
    `SELECT COLUMN_NAME
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'review'
       AND COLUMN_NAME = 'review_like'`
  );

  if (!likeColumns.length) {
    await pool.query('ALTER TABLE review ADD COLUMN review_like INT NOT NULL DEFAULT 0');
  }
}

async function saveReviewImage(rawImage) {
  const value = String(rawImage || '').trim();
  if (!value) return null;
  if (!value.startsWith('data:image/')) return value.slice(0, 100);

  const match = value.match(/^data:image\/(png|jpeg|jpg);base64,(.+)$/);
  if (!match) return null;

  const extension = match[1] === 'png' ? 'png' : 'jpg';
  const uploadDir = path.join(__dirname, 'uploads', 'reviews');
  await fs.promises.mkdir(uploadDir, { recursive: true });

  const fileName = `review_${Date.now()}_${Math.random().toString(36).slice(2)}.${extension}`;
  await fs.promises.writeFile(path.join(uploadDir, fileName), Buffer.from(match[2], 'base64'));
  return `/uploads/reviews/${fileName}`.slice(0, 100);
}

app.get('/products', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        p.product_seq,
        p.product_name,
        p.product_qty,
        p.product_price,
        p.product_category_seq,
        p.product_sub_category_seq,
        COALESCE(pc.product_category_name, '') AS raw_category_name,
        COALESCE(psc.product_sub_category_name, '') AS raw_sub_category_name,
        CASE
          WHEN COALESCE(pc.product_category_name, '') LIKE '%사료%'
            OR COALESCE(psc.product_sub_category_name, '') LIKE '%사료%'
            OR COALESCE(p.product_name, '') LIKE '%사료%'
          THEN '사료'

          WHEN COALESCE(pc.product_category_name, '') LIKE '%간식%'
            OR COALESCE(psc.product_sub_category_name, '') LIKE '%간식%'
            OR COALESCE(p.product_name, '') LIKE '%간식%'
          THEN '간식'

          WHEN COALESCE(pc.product_category_name, '') LIKE '%목줄%'
            OR COALESCE(psc.product_sub_category_name, '') LIKE '%목줄%'
            OR COALESCE(p.product_name, '') LIKE '%목줄%'
            OR COALESCE(p.product_name, '') LIKE '%리드%'
          THEN '목줄'

          WHEN COALESCE(pc.product_category_name, '') LIKE '%하네스%'
            OR COALESCE(psc.product_sub_category_name, '') LIKE '%하네스%'
            OR COALESCE(p.product_name, '') LIKE '%하네스%'
          THEN '하네스'

          WHEN COALESCE(pc.product_category_name, '') LIKE '%의류%'
            OR COALESCE(psc.product_sub_category_name, '') LIKE '%의류%'
            OR COALESCE(p.product_name, '') LIKE '%의류%'
          THEN '의류'

          WHEN COALESCE(pc.product_category_name, '') LIKE '%장난감%'
            OR COALESCE(psc.product_sub_category_name, '') LIKE '%장난감%'
            OR COALESCE(p.product_name, '') LIKE '%장난감%'
            OR COALESCE(p.product_name, '') LIKE '%노즈워크%'
          THEN '장난감'

          ELSE '기타'
        END AS product_category_name
      FROM product p
      LEFT JOIN product_category pc ON p.product_category_seq = pc.product_category_seq
      LEFT JOIN product_sub_category psc ON p.product_sub_category_seq = psc.product_sub_category_seq
      ORDER BY p.product_seq DESC
    `);

    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});



app.get('/products/:productSeq/image', async (req, res) => {
  try {
    const productSeq = Number(req.params.productSeq);
    const [rows] = await pool.query(
      'SELECT product_image, product_thumbnail FROM product WHERE product_seq = ? LIMIT 1',
      [productSeq]
    );

    if (!rows.length) {
      return res.status(404).send('not found');
    }

    const buffer = rows[0].product_image || rows[0].product_thumbnail;
    if (!buffer) {
      return res.status(404).send('no image');
    }

    const b = Buffer.from(buffer);
    let contentType = 'application/octet-stream';
    if (b.length >= 4 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4E && b[3] === 0x47) {
      contentType = 'image/png';
    } else if (b.length >= 2 && b[0] === 0xFF && b[1] === 0xD8) {
      contentType = 'image/jpeg';
    } else if (b.length >= 3 && b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46) {
      contentType = 'image/gif';
    }

    res.setHeader('Content-Type', contentType);
    res.send(b);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/products/:productSeq/thumbnail', async (req, res) => {
  try {
    const productSeq = Number(req.params.productSeq);
    const [rows] = await pool.query(
      'SELECT product_thumbnail, product_image FROM product WHERE product_seq = ? LIMIT 1',
      [productSeq]
    );

    if (!rows.length) {
      return res.status(404).send('not found');
    }

    const buffer = rows[0].product_thumbnail || rows[0].product_image;
    if (!buffer) {
      return res.status(404).send('no image');
    }

    const b = Buffer.from(buffer);
    let contentType = 'application/octet-stream';
    if (b.length >= 4 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4E && b[3] === 0x47) {
      contentType = 'image/png';
    } else if (b.length >= 2 && b[0] === 0xFF && b[1] === 0xD8) {
      contentType = 'image/jpeg';
    } else if (b.length >= 3 && b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46) {
      contentType = 'image/gif';
    }

    res.setHeader('Content-Type', contentType);
    res.send(b);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/reviews', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT r.review_seq, r.product_seq, r.user_seq, r.buy_seq, r.review_title, r.review_content,
             r.review_image, r.review_rating,
             COALESCE(r.review_like, 0) AS review_like,
             DATE_FORMAT(r.review_date, '%Y-%m-%d') AS review_date,
             p.product_name, u.user_name
      FROM review r
      LEFT JOIN product p ON r.product_seq = p.product_seq
      LEFT JOIN users u ON r.user_seq = u.user_seq
      ORDER BY r.review_seq DESC
    `);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/reviews', async (req, res) => {
  const { product_seq, user_seq, buy_seq, review_title, review_content, review_image, review_rating } = req.body;
  try {
    const buySeq = Number(buy_seq || 0);
    const purchaseQuery = buySeq > 0
      ? {
          sql: 'SELECT buy_seq FROM buy WHERE buy_seq = ? AND product_seq = ? AND user_seq = ? LIMIT 1',
          values: [buySeq, product_seq, user_seq]
        }
      : {
          sql: `SELECT b.buy_seq
                FROM buy b
                LEFT JOIN review r ON r.buy_seq = b.buy_seq
                WHERE b.product_seq = ?
                  AND b.user_seq = ?
                  AND r.review_seq IS NULL
                ORDER BY b.buy_seq DESC
                LIMIT 1`,
          values: [product_seq, user_seq]
        };

    const [purchaseRows] = await pool.query(purchaseQuery.sql, purchaseQuery.values);

    if (!purchaseRows.length) {
      return res.status(403).json({ message: '구매했거나 아직 리뷰를 쓰지 않은 주문만 후기를 작성할 수 있습니다.' });
    }

    const reviewBuySeq = purchaseRows[0].buy_seq;
    const [duplicateRows] = await pool.query(
      'SELECT review_seq FROM review WHERE buy_seq = ? LIMIT 1',
      [reviewBuySeq]
    );

    if (duplicateRows.length) {
      return res.status(409).json({ message: '이미 해당 구매건의 후기를 작성했습니다.' });
    }

    const storedReviewImage = await saveReviewImage(review_image);
    const [result] = await pool.query(
      `INSERT INTO review (product_seq, user_seq, buy_seq, review_title, review_content, review_image, review_rating, review_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
      [product_seq, user_seq, reviewBuySeq, review_title ?? null, review_content, storedReviewImage, review_rating ?? null]
    );

    const [rows] = await pool.query(`
      SELECT r.review_seq, r.product_seq, r.user_seq, r.buy_seq, r.review_title, r.review_content,
             r.review_image, r.review_rating,
             COALESCE(r.review_like, 0) AS review_like,
             DATE_FORMAT(r.review_date, '%Y-%m-%d') AS review_date,
             p.product_name, u.user_name
      FROM review r
      LEFT JOIN product p ON r.product_seq = p.product_seq
      LEFT JOIN users u ON r.user_seq = u.user_seq
      WHERE r.review_seq = ?
    `, [result.insertId]);

    res.status(201).json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/reviews/:reviewSeq/like', async (req, res) => {
  const reviewSeq = Number(req.params.reviewSeq);

  if (!Number.isFinite(reviewSeq) || reviewSeq <= 0) {
    return res.status(400).json({ message: '좋아요를 누를 후기 정보가 부족합니다.' });
  }

  try {
    const [result] = await pool.query(
      'UPDATE review SET review_like = COALESCE(review_like, 0) + 1 WHERE review_seq = ?',
      [reviewSeq]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '후기를 찾을 수 없습니다.' });
    }

    const [rows] = await pool.query(`
      SELECT r.review_seq, r.product_seq, r.user_seq, r.buy_seq, r.review_title, r.review_content,
             r.review_image, r.review_rating,
             COALESCE(r.review_like, 0) AS review_like,
             DATE_FORMAT(r.review_date, '%Y-%m-%d') AS review_date,
             p.product_name, u.user_name
      FROM review r
      LEFT JOIN product p ON r.product_seq = p.product_seq
      LEFT JOIN users u ON r.user_seq = u.user_seq
      WHERE r.review_seq = ?
    `, [reviewSeq]);

    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.patch('/reviews/:reviewSeq', async (req, res) => {
  const reviewSeq = Number(req.params.reviewSeq);
  const { user_seq, review_title, review_content, review_image, review_rating } = req.body;

  if (!Number.isFinite(reviewSeq) || reviewSeq <= 0 || !user_seq || !review_title || !review_content) {
    return res.status(400).json({ message: '후기 수정 정보가 부족합니다.' });
  }

  try {
    const storedReviewImage = review_image ? await saveReviewImage(review_image) : null;
    const [result] = storedReviewImage
      ? await pool.query(
          `UPDATE review
           SET review_title = ?, review_content = ?, review_image = ?, review_rating = ?
           WHERE review_seq = ? AND user_seq = ?`,
          [review_title, review_content, storedReviewImage, review_rating ?? 5, reviewSeq, user_seq]
        )
      : await pool.query(
          `UPDATE review
           SET review_title = ?, review_content = ?, review_rating = ?
           WHERE review_seq = ? AND user_seq = ?`,
          [review_title, review_content, review_rating ?? 5, reviewSeq, user_seq]
        );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '수정할 후기를 찾을 수 없습니다.' });
    }

    const [rows] = await pool.query(`
      SELECT r.review_seq, r.product_seq, r.user_seq, r.buy_seq, r.review_title, r.review_content,
             r.review_image, r.review_rating,
             COALESCE(r.review_like, 0) AS review_like,
             DATE_FORMAT(r.review_date, '%Y-%m-%d') AS review_date,
             p.product_name, u.user_name
      FROM review r
      LEFT JOIN product p ON r.product_seq = p.product_seq
      LEFT JOIN users u ON r.user_seq = u.user_seq
      WHERE r.review_seq = ?
    `, [reviewSeq]);

    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.delete('/reviews/:reviewSeq', async (req, res) => {
  const reviewSeq = Number(req.params.reviewSeq);
  const userSeq = Number(req.query.user_seq);
  await deleteReviewForUser(req, res, reviewSeq, userSeq);
});

app.delete('/reviews/:reviewSeq/users/:userSeq', async (req, res) => {
  const reviewSeq = Number(req.params.reviewSeq);
  const userSeq = Number(req.params.userSeq);
  await deleteReviewForUser(req, res, reviewSeq, userSeq);
});

async function deleteReviewForUser(req, res, reviewSeq, userSeq) {
  if (!Number.isFinite(reviewSeq) || reviewSeq <= 0 || !Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '삭제할 후기 정보가 부족합니다.' });
  }

  try {
    const [result] = await pool.query(
      'DELETE FROM review WHERE review_seq = ? AND user_seq = ?',
      [reviewSeq, userSeq]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '삭제할 후기를 찾을 수 없습니다.' });
    }

    res.json({ message: '후기가 삭제되었습니다.' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

app.get('/users/:userSeq/purchases', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT b.buy_seq,
              DATE_FORMAT(b.buy_date, '%Y-%m-%d') AS buy_date,
              b.buy_qty,
              b.buy_price,
              b.product_seq,
              b.user_seq,
              CASE WHEN r.review_seq IS NULL THEN false ELSE true END AS has_review
       FROM buy b
       LEFT JOIN review r ON r.buy_seq = b.buy_seq
       WHERE b.user_seq = ?
       ORDER BY b.buy_seq DESC`,
      [userSeq]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/users/:userSeq/addresses', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT address_seq, user_seq, address_name, address
       FROM address
       WHERE user_seq = ?
         AND address IS NOT NULL
         AND TRIM(address) <> ''
       ORDER BY address_seq DESC`,
      [userSeq]
    );

    const seen = new Set();
    const uniqueRows = [];
    for (const row of rows) {
      const key = String(row.address || '').trim().replace(/\s+/g, ' ');
      if (seen.has(key)) continue;
      seen.add(key);
      uniqueRows.push(row);
    }

    res.json(uniqueRows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/users/:userSeq/purchases', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  const { items, address } = req.body;

  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: '결제할 상품이 필요합니다.' });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const inserted = [];
    for (const item of items) {
      const productSeq = Number(item.product_seq);
      const quantity = Math.max(1, Number(item.quantity || 1));
      const price = Number(item.price || 0);

      if (!Number.isFinite(productSeq) || productSeq <= 0) {
        throw new Error('유효한 product_seq가 필요합니다.');
      }

      const [result] = await connection.query(
        `INSERT INTO buy (buy_date, buy_qty, buy_price, product_seq, user_seq)
         VALUES (NOW(), ?, ?, ?, ?)`,
        [quantity, price * quantity, productSeq, userSeq]
      );

      inserted.push({
        buy_seq: result.insertId,
        product_seq: productSeq,
        user_seq: userSeq
      });
    }

    const parsedAddress = parseDeliveryAddress(address);
    if (parsedAddress.address) {
      const [existingAddresses] = await connection.query(
        `SELECT address_seq
         FROM address
         WHERE user_seq = ?
           AND address = ?
         LIMIT 1`,
        [userSeq, parsedAddress.address]
      );

      if (existingAddresses.length === 0) {
        await connection.query(
          `INSERT INTO address (user_seq, address_name, address)
           VALUES (?, ?, ?)`,
          [userSeq, parsedAddress.name, parsedAddress.address]
        );
      } else {
        await connection.query(
          `UPDATE address
           SET address_name = ?
           WHERE address_seq = ?`,
          [parsedAddress.name, existingAddresses[0].address_seq]
        );
      }
    }

    await connection.commit();
    res.status(201).json(inserted);
  } catch (e) {
    await connection.rollback();
    res.status(500).json({ message: e.message });
  } finally {
    connection.release();
  }
});

function parseDeliveryAddress(rawAddress) {
  const raw = String(rawAddress || '').trim();
  if (!raw) {
    return { name: '최근 배송지', address: '' };
  }

  const parts = raw.split(' / ').map((part) => part.trim()).filter(Boolean);
  if (parts.length >= 3) {
    return {
      name: `${parts[0]} / ${parts[1]}`.slice(0, 100),
      address: parts.slice(2).join(' / ').slice(0, 100)
    };
  }

  return {
    name: '최근 배송지',
    address: raw.slice(0, 100)
  };
}

app.post('/auth/login', async (req, res) => {
  const { user_id, user_pw } = req.body;

  if (!user_id || !user_pw) {
    return res.status(400).json({ message: 'user_id, user_pw는 필수입니다.' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash
       FROM users
       WHERE user_id = ? AND user_pw = ?
       LIMIT 1`,
      [user_id, user_pw]
    );

    if (!rows.length) {
      return res.status(401).json({ message: '아이디 또는 비밀번호가 올바르지 않습니다.' });
    }

    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/auth/find-id', async (req, res) => {
  const { user_name, user_phone } = req.body;

  if (!user_name || !user_phone) {
    return res.status(400).json({ message: '이름과 전화번호를 입력해주세요.' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT user_id
       FROM users
       WHERE user_name = ?
         AND REPLACE(COALESCE(user_phone, ''), '-', '') = REPLACE(?, '-', '')
       LIMIT 1`,
      [String(user_name).trim(), String(user_phone).trim()]
    );

    if (!rows.length) {
      return res.status(404).json({ message: '일치하는 계정을 찾을 수 없습니다.' });
    }

    res.json({ user_id: rows[0].user_id, message: '가입 아이디를 찾았습니다.' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/auth/reset-password', async (req, res) => {
  const { user_id, user_pw } = req.body;
  const email = String(user_id || '').trim();
  const password = String(user_pw || '');

  if (!isValidEmail(email) || !password) {
    return res.status(400).json({ message: '아이디와 새 비밀번호를 확인해주세요.' });
  }
  if (password.length < 8 || !/[A-Za-z]/.test(password)) {
    return res.status(400).json({ message: '비밀번호는 8자 이상, 영문 포함이어야 합니다.' });
  }

  const verifiedAt = verifiedEmails.get(email);
  if (!verifiedAt || Date.now() - verifiedAt > 10 * 60 * 1000) {
    return res.status(403).json({ message: '이메일 인증을 먼저 완료해주세요.' });
  }

  try {
    const [result] = await pool.query(
      'UPDATE users SET user_pw = ? WHERE user_id = ?',
      [password, email]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '일치하는 계정을 찾을 수 없습니다.' });
    }

    verifiedEmails.delete(email);
    res.json({ message: '비밀번호가 변경되었습니다.' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

async function handleCheckUserID(req, res) {
  const { user_id } = req.body;

  if (!user_id) {
    return res.status(400).json({ available: false, message: 'user_id는 필수입니다.' });
  }
  if (!isValidEmail(user_id)) {
    return res.status(400).json({ available: false, message: '이메일 형식이 올바르지 않습니다.' });
  }

  try {
    const [rows] = await pool.query(
      'SELECT user_seq FROM users WHERE user_id = ? LIMIT 1',
      [user_id]
    );

    const available = rows.length === 0;
    res.json({
      available,
      exists: !available,
      is_duplicate: !available,
      message: available ? '사용 가능한 아이디입니다.' : '이미 사용 중인 아이디입니다.'
    });
  } catch (e) {
    res.status(500).json({ available: false, message: e.message });
  }
}

app.post('/auth/check-id', handleCheckUserID);
app.post('/auth/check-user-id', handleCheckUserID);
app.post('/users/check-id', handleCheckUserID);

app.post('/auth/signup', async (req, res) => {
  const { user_id, user_pw, user_name, user_phone } = req.body;

  if (!user_id || !user_pw || !user_name) {
    return res.status(400).json({ message: 'user_id, user_pw, user_name은 필수입니다.' });
  }
  if (!isValidEmail(user_id)) {
    return res.status(400).json({ message: '이메일 형식이 올바르지 않습니다.' });
  }

  const verifiedAt = verifiedEmails.get(user_id);
  if (!verifiedAt || Date.now() - verifiedAt > 10 * 60 * 1000) {
    return res.status(403).json({ message: '이메일 인증을 먼저 완료해주세요.' });
  }

  try {
    const [dupRows] = await pool.query(
      'SELECT user_seq FROM users WHERE user_id = ? LIMIT 1',
      [user_id]
    );

    if (dupRows.length) {
      return res.status(409).json({ message: '이미 사용 중인 아이디입니다.' });
    }

    const [insertResult] = await pool.query(
      `INSERT INTO users (user_name, user_phone, user_id, user_pw, user_date)
       VALUES (?, ?, ?, ?, NOW())`,
      [user_name, user_phone ?? null, user_id, user_pw]
    );

    const [rows] = await pool.query(
      `SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash
       FROM users
       WHERE user_seq = ?
       LIMIT 1`,
      [insertResult.insertId]
    );

    verifiedEmails.delete(user_id);
    res.status(201).json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/users/:userSeq', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash
       FROM users
       WHERE user_seq = ?
       LIMIT 1`,
      [userSeq]
    );

    if (!rows.length) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

async function handleUpdateQuickPin(req, res) {
  const userSeq = Number(req.params.userSeq);
  const { quick_pin_hash } = req.body;

  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }
  if (!/^[a-f0-9]{64}$/i.test(String(quick_pin_hash || ''))) {
    return res.status(400).json({ message: 'quick_pin_hash는 SHA-256 해시 64자리여야 합니다.' });
  }

  try {
    const [result] = await pool.query(
      'UPDATE users SET quick_pin_hash = ? WHERE user_seq = ?',
      [quick_pin_hash, userSeq]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    res.json({ message: '간편 비밀번호가 저장되었습니다.' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

app.patch('/users/:userSeq/quick-pin', handleUpdateQuickPin);
app.patch('/users/:userSeq/pin', handleUpdateQuickPin);

app.post('/auth/email/send-code', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ message: 'email은 필수입니다.' });
  }
  if (!isValidEmail(email)) {
    return res.status(400).json({ message: '이메일 형식이 올바르지 않습니다.' });
  }
  const cooldown = emailCodeCooldown.get(email);
  if (cooldown && Date.now() < cooldown) {
    const waitSec = Math.ceil((cooldown - Date.now()) / 1000);
    return res.status(429).json({ message: `요청이 너무 빠릅니다. ${waitSec}초 후 다시 시도해주세요.` });
  }

  const code = createVerificationCode();
  emailVerificationCodes.set(email, { code, expiresAt: Date.now() + 5 * 60 * 1000 });
  emailCodeCooldown.set(email, Date.now() + 60 * 1000);
  res.json({
    message: '인증코드를 발급했습니다. 아래 코드를 앱에 입력해주세요.',
    verification_code: code
  });
});

app.post('/auth/email/verify-code', async (req, res) => {
  const { email, code } = req.body;
  if (!email || !code) {
    return res.status(400).json({ message: 'email, code는 필수입니다.' });
  }
  if (!isValidEmail(email)) {
    return res.status(400).json({ message: '이메일 형식이 올바르지 않습니다.' });
  }

  const saved = emailVerificationCodes.get(email);
  if (!saved) {
    return res.status(400).json({ message: '인증코드가 없거나 만료되었습니다.' });
  }

  if (Date.now() > saved.expiresAt) {
    emailVerificationCodes.delete(email);
    return res.status(400).json({ message: '인증코드가 만료되었습니다.' });
  }

  if (saved.code !== String(code).trim()) {
    return res.status(400).json({ message: '인증코드가 올바르지 않습니다.' });
  }

  emailVerificationCodes.delete(email);
  verifiedEmails.set(email, Date.now());
  res.json({ message: '이메일 인증이 완료되었습니다.' });
});

app.get('/users/:userSeq/dogs', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT
         d.dog_seq,
         COALESCE(d.dog_name, CONCAT('반려견-', d.dog_seq)) AS dog_name,
         COALESCE(db.dog_breeds_name, '견종 미상') AS breed_name,
         COALESCE(da.dog_age, '나이 미상') AS age_name,
         CASE
           WHEN d.dog_weight IS NULL THEN '체중 미상'
           ELSE CONCAT(TRIM(TRAILING '.0' FROM CAST(d.dog_weight AS CHAR)), 'kg')
         END AS weight_text,
         COALESCE(dc.dog_color_name, '') AS color_name
       FROM dog d
       LEFT JOIN dog_breeds db ON d.dog_breeds_seq = db.dog_breeds_seq
       LEFT JOIN dog_age da ON d.dog_age_seq = da.dog_age_seq
       LEFT JOIN dog_color dc ON d.dog_color_seq = dc.dog_color_seq
       WHERE d.user_seq = ?
       ORDER BY d.dog_seq DESC`,
      [userSeq]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/users/:userSeq/dogs', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  const { dog_name, breed_name, age_name, weight_text, color_name } = req.body;

  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }
  if (!dog_name || !breed_name || !age_name || !color_name) {
    return res.status(400).json({ message: 'dog_name, breed_name, age_name, color_name은 필수입니다.' });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [userRows] = await connection.query(
      'SELECT user_seq FROM users WHERE user_seq = ? LIMIT 1',
      [userSeq]
    );
    if (!userRows.length) {
      await connection.rollback();
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    const dogBreedsSeq = await findOrCreateLookup(
      connection,
      'dog_breeds',
      'dog_breeds_seq',
      'dog_breeds_name',
      breed_name
    );
    const dogAgeSeq = await findOrCreateLookup(
      connection,
      'dog_age',
      'dog_age_seq',
      'dog_age',
      age_name
    );
    const dogColorSeq = await findOrCreateLookup(
      connection,
      'dog_color',
      'dog_color_seq',
      'dog_color_name',
      color_name
    );
    const dogWeight = parseDogWeight(weight_text);

    const [insertResult] = await connection.query(
      `INSERT INTO dog (dog_name, user_seq, dog_weight, dog_breeds_seq, dog_age_seq, dog_color_seq)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [dog_name, userSeq, dogWeight, dogBreedsSeq, dogAgeSeq, dogColorSeq]
    );

    await connection.commit();

    res.status(201).json({
      dog_seq: insertResult.insertId,
      dog_name,
      breed_name,
      age_name,
      weight_text: weight_text ?? '체중 미상',
      color_name
    });
  } catch (e) {
    await connection.rollback();
    res.status(500).json({ message: e.message });
  } finally {
    connection.release();
  }
});

app.delete('/users/:userSeq/dogs/:dogSeq', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  const dogSeq = Number(req.params.dogSeq);

  if (!Number.isFinite(userSeq) || userSeq <= 0 || !Number.isFinite(dogSeq) || dogSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq와 dogSeq가 필요합니다.' });
  }

  try {
    const [result] = await pool.query(
      'DELETE FROM dog WHERE user_seq = ? AND dog_seq = ?',
      [userSeq, dogSeq]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: '삭제할 강아지를 찾을 수 없습니다.' });
    }

    res.json({ message: '강아지 정보가 삭제되었습니다.' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/users/:userSeq/notifications', async (req, res) => {
  const userSeq = Number(req.params.userSeq);
  if (!Number.isFinite(userSeq) || userSeq <= 0) {
    return res.status(400).json({ message: '유효한 userSeq가 필요합니다.' });
  }

  try {
    const [buyRows] = await pool.query(
      `SELECT
         '주문' AS category,
         CONCAT(COALESCE(p.product_name, '상품'), ' 주문 내역이 있어요') AS title,
         CONCAT(DATE_FORMAT(b.buy_date, '%Y-%m-%d'), ' 주문 수량 ', COALESCE(b.buy_qty, 0), '개') AS detail,
         1 AS is_new
       FROM buy b
       LEFT JOIN product p ON b.product_seq = p.product_seq
       WHERE b.user_seq = ?
       ORDER BY b.buy_seq DESC
       LIMIT 5`,
      [userSeq]
    );

    const [reviewRows] = await pool.query(
      `SELECT
         '리뷰' AS category,
         CONCAT(COALESCE(p.product_name, '상품'), ' 리뷰가 등록되어 있어요') AS title,
         CONCAT('리뷰 내용: ', LEFT(COALESCE(r.review_content, ''), 30)) AS detail,
         0 AS is_new
       FROM review r
       LEFT JOIN product p ON r.product_seq = p.product_seq
       WHERE r.user_seq = ?
       ORDER BY r.review_seq DESC
       LIMIT 5`,
      [userSeq]
    );

    const notifications = [...buyRows, ...reviewRows].slice(0, 10);
    res.json(notifications);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

const port = Number(process.env.PORT || 8000);
ensureReviewColumns()
  .then(() => {
    app.listen(port, () => {
      console.log(`API running on port ${port}`);
    });
  })
  .catch((error) => {
    console.error('Failed to prepare database schema:', error);
    process.exit(1);
  });
