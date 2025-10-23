-- Scenario: Online Bookstore Database
-- You've been asked to design a database for an online bookstore. The system needs to handle:

-- Books: Each book has a title, author(s), ISBN, publication year, genre, price, and description
-- Customers: People who buy books need accounts with their contact information
-- Orders: Customers can place orders containing multiple books
-- Reviews: Customers can write reviews for books they've purchased, including a rating (1-5 stars) and text comments
-- Inventory: The store needs to track how many copies of each book are in stock

CREATE TABLE book(
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(13) UNIQUE NOT NULL,
    publication_year INT,
    genre VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE author(
    id UUID PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255)
);

CREATE TABLE book_author(
    book_id UUID,
    author_id UUID,
    author_order INT, -- For display order
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE CASCADE
);

CREATE TABLE customer(
    id UUID PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_address(
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip VARCHAR(10) NOT NULL,
    address_type ENUM('billing', 'shipping') NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE
);

CREATE TABLE `order`(
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipping_address_id UUID,
    FOREIGN KEY (customer_id) REFERENCES customer(id),
    FOREIGN KEY (shipping_address_id) REFERENCES customer_address(id)
);

CREATE TABLE order_item(
    id UUID PRIMARY KEY,
    order_id UUID NOT NULL,
    book_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price_at_purchase DECIMAL(10,2) NOT NULL, -- Store historical price
    FOREIGN KEY (order_id) REFERENCES `order`(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book(id)
);

CREATE TABLE review(
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    book_id UUID NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
    UNIQUE KEY unique_customer_book (customer_id, book_id)
);

CREATE TABLE inventory(
    book_id UUID PRIMARY KEY,
    quantity_available INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE
);
