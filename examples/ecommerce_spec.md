# E-Commerce Platform

An online store where vendors can list products and customers can browse,
search, and purchase items. Includes a shopping cart and order tracking.

## Features
- Product catalog with categories
- Shopping cart
- User accounts (customers and vendors)
- Order placement and tracking
- Payment processing
- Product search with filters
- Product reviews and ratings
- Inventory management for vendors

## Pages
- Home page with featured products
- Product listing page with filters
- Product detail page
- Shopping cart page
- Checkout page
- Order history page
- Vendor dashboard
- Admin panel

## API Endpoints
- GET /products
- GET /products/:id
- POST /products (vendor)
- PUT /products/:id (vendor)
- DELETE /products/:id (vendor)
- GET /categories
- POST /cart/add
- GET /cart
- DELETE /cart/:itemId
- POST /orders
- GET /orders
- GET /orders/:id
- POST /auth/signup
- POST /auth/login
- POST /reviews
- GET /products/:id/reviews
