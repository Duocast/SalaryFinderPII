import os
import re
import shutil
import socket
from pathlib import Path

def find_salary_files(start_directory):
    regex_pattern = r'\b(?:USD|usd)?\s*\$?\s*\d{1,3}(?:[,\s]\d{3})*(?:\.\d{2})?\s*(?:USD|usd)?\b'
    regex = re.compile(regex_pattern)
    keywords = ['salary', 'compensation', 'pay']
    keyword_distance = 50

    def contains_keyword_near_match(match, content):
        start_index = max(0, match.start() - keyword_distance)
        end_index = min(len(content), match.end() + keyword_distance)
        surrounding_text = content[start_index:end_index].lower()
        return any(keyword in surrounding_text for keyword in keywords)

    for root, _, files in os.walk(start_directory):
        for file in files:
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                matches = list(regex.finditer(content))
                for match in matches:
                    if contains_keyword_near_match(match, content):
                        yield file_path
                        break

def copy_file_and_create_info_file(src, dest_folder, hostname):
    dest_file = os.path.join(dest_folder, os.path.basename(src))
    shutil.copy(src, dest_file)

    info_filename = os.path.basename(src) + "_info.txt"
    info_filepath = os.path.join(dest_folder, info_filename)
    with open(info_filepath, 'w') as f:
        f.write(f"File location: {src}\n")
        f.write(f"Hostname: {hostname}\n")

def main():
    user_folders = ['Documents', 'Downloads', 'Desktop']
    shared_folder = '\\\\s-amusdat-ile03\Cyber-Review\CyberHunt\Global Hunt\\'
    Path(shared_folder).mkdir(parents=True, exist_ok=True)

    hostname = socket.gethostname()

    users_path = 'C:\\Users'
    for user in os.listdir(users_path):
        user_path = os.path.join(users_path, user)
        if os.path.isdir(user_path):
            for user_folder in user_folders:
                target_directory = os.path.join(user_path, user_folder)
                if os.path.exists(target_directory):
                    for salary_file in find_salary_files(target_directory):
                        copy_file_and_create_info_file(salary_file, shared_folder, hostname)

if __name__ == "__main__":
    main()
