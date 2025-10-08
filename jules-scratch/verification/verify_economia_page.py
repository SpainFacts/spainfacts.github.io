from playwright.sync_api import sync_playwright, Page, expect

def verify_frontend_changes():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        try:
            # Navigate to the homepage
            page.goto("http://localhost:3000/", timeout=60000)

            # Find and click the "Economía" link in the header
            economia_link = page.get_by_role("link", name="Economía")
            expect(economia_link).to_be_visible()
            economia_link.click()

            # Wait for the new page to load and verify the title
            expect(page).to_have_title("Datos Económicos de España", timeout=30000)

            # Verify that the main heading is visible
            main_heading = page.get_by_role("heading", name="Panel de Datos Económicos")
            expect(main_heading).to_be_visible()

            # Take a screenshot of the new dashboard
            screenshot_path = "jules-scratch/verification/economia_dashboard.png"
            page.screenshot(path=screenshot_path)
            print(f"Screenshot saved to {screenshot_path}")

        except Exception as e:
            print(f"An error occurred during verification: {e}")
            # In case of error, take a screenshot for debugging
            page.screenshot(path="jules-scratch/verification/error_screenshot.png")
        finally:
            browser.close()

if __name__ == "__main__":
    verify_frontend_changes()