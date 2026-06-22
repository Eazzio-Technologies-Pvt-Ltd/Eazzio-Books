/**
 * api.js – Central API helper with cookie auth
 * Dependencies: none
 */

// CRA automatically reads .env — no dotenv import needed
const BASE_URL = process.env.REACT_APP_API_URL || 'https://eazzio-books.onrender.com/api';

export async function apiRequest(path, options = {}) {
  try {
    const res = await fetch(`${BASE_URL}${path}`, {
      ...options,
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {})
      }
    });

    const text = await res.text();

    let data;
    try {
      data = JSON.parse(text);
    } catch {
      throw new Error("Invalid server response");
    }

    if (!res.ok) {
      if (res.status === 401) {
        return null; // no redirect
      }
      if (res.status === 402) {
        window.dispatchEvent(new CustomEvent("subscription-expired"));
        throw new Error(data.message || 'Subscription expired');
      }
      throw new Error(data.message || 'API error');
    }

    return data;
  } catch (error) {
    console.error("API Error:", error.message);
    throw error;
  }
}