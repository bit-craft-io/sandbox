import requests
from bs4 import BeautifulSoup

class Scraper:
    def __init__(self, url: str, user_agent: str = "Mozilla/5.0 (compatible; MyRAGBot/1.0)"):
        self.url = url
        self.headers = {"User-Agent": user_agent}

    def fetch(self, selector: str = None, attr: str = "id") -> str:
        res = requests.get(self.url, headers=self.headers)
        res.encoding = "utf-8"
        soup = BeautifulSoup(res.text, "html.parser")

        if selector:
            content = soup.find("div", {attr: selector})
            return content.get_text(separator="\n", strip=True) if content else ""

        return soup.get_text(separator="\n", strip=True)