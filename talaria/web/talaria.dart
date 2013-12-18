import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:convert';
import 'dart:async';

const String REPOSITORY_NAME = 'm2w.github.com';
const String GITHUB_USERNAME = 'm2w';
const String COMMENTABLE_CONTENT_PATH_PREFIX = '_posts/';
const String CONTENT_SUFFIX = '.md';
const String COMMENT_API_ENDPOINT = 'https://api.github.com/repos/${GITHUB_USERNAME}/${REPOSITORY_NAME}/comments';
const String COMMIT_API_ENDPOINT = 'https://api.github.com/repos/${GITHUB_USERNAME}/${REPOSITORY_NAME}/commits';
const String REPO_COMMIT_URL_ROOT = 'https://github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}/commit/';


@CustomTag('talaria-comments')
class TalariaComments extends PolymerElement {
  String path;
  String permalink;
  @published List comments = [];
  @published String newest_commit_url;
  
  TalariaComments.created() : super.created() {
  }
  
  @override
  void enteredView() {
    super.enteredView();
    path = extrapolatePathFromPermalink(permalink);
    
    if (!window.sessionStorage.containsKey(path)) {
      _retrieveCommitData(path);  
    } else {
      // TODO for some reason this doesn't work as I expect it to, move it into another lifecycle callback?
      this.comments = JSON.decode(window.sessionStorage[path]).map((comment) => Comment.fromJson(comment));
    }
  }

  void _retrieveCommitData(resourcePath){
    HttpRequest.request('${COMMIT_API_ENDPOINT}?path=${resourcePath}', method: 'get', 
        requestHeaders: {'Accept':'application/vnd.github.v3.text+json' }).then(_retrieveComments);
  }
  
  void _retrieveComments(HttpRequest apiResponse) {
    List commits = JSON.decode(apiResponse.response);
    newest_commit_url = '${REPO_COMMIT_URL_ROOT}${commits.first["sha"]}';
    Future.wait(commits.map(_retrieveCommitComments)).then(_handleComments);
  }
  
  Future _retrieveCommitComments(commit) {
    var x = commit['sha'];
    return HttpRequest.request('${COMMIT_API_ENDPOINT}/${commit['sha']}/comments', method: 'get', 
        requestHeaders: {'Accept':'application/vnd.github.v3.text+json' }).then(_handleCommentsForCommit);
  }
  
  Future _handleCommentsForCommit(HttpRequest apiResponse) {
    List comments = JSON.decode(apiResponse.response);
    return new Future.value(comments);
  }
  
  void _handleComments(List comments) {
    this.comments = comments.expand((commit) => commit.map(
        (comment) => 
            new Comment(
                comment['commit_id'], 
                comment['user']['login'], 
                comment['user']['html_url'], 
                comment['user']['avatar_url'], 
                DateTime.parse(comment['updated_at']), 
                comment['body_text']))).toList()
                  ..sort((Comment a, Comment b) => a._time.compareTo(b._time));
    window.sessionStorage[path] = JSON.encode(this.comments);
  }
}

class Comment {
  String sha, author_name, author_profile, avatar, body;
  DateTime _time;
  String get commit_url => '${REPO_COMMIT_URL_ROOT}${sha}';
  String get time => relativeTimeElapsed(this._time);
  String get short_sha => sha.substring(0, 6);
  
  static Comment fromJson(Map json) {
    return new Comment(
        json['sha'], 
        json['author_name'], 
        json['author_profile'], 
        json['avatar'], 
        DateTime.parse(json['time']), 
        json['body']);
  }

  Comment(this.sha, this.author_name, this.author_profile, this.avatar, this._time, this.body);
  
  @override
  String toString() => '<<Comment for ${sha} by ${author_name}, posted ${time}>>';
  
  Map toJson() {
    var map = new Map();
    map['sha'] = sha;
    map['time'] = _time.toString();
    map['author_name'] = author_name;
    map['author_profile'] = author_profile;
    map['avatar'] = avatar;
    map['body'] = body;
    return map;
  }
}

final RegExp permalink = new RegExp(r'(?:[\.\w\-_:/]+)?/(\d+)/(\d+)/(\d+)/([\w\-_]+)$');
String extrapolatePathFromPermalink(String permalink_url) {
  return permalink_url.replaceAllMapped(permalink, 
      (Match m) => '${COMMENTABLE_CONTENT_PATH_PREFIX}${m[1]}-${m[2]}-${m[3]}-${m[4]}${CONTENT_SUFFIX}');
}


const int JUST_NOW_LIMIT = 5; // anything less than 5 minutes is "just now" 
String relativeTimeElapsed(DateTime before) {
  String pluralize(int elapsedTime, String step) {
    return '${elapsedTime} ${step}${(elapsedTime == 1 ? '': 's')} ago';
  }
  
  var now = new DateTime.now();
  var elapsed = now.difference(before);
  
  // TODO, check months and years, currently seems to always add 1
  if (elapsed.inDays > 365) {
    var years = elapsed.inDays ~/ 365;
    return pluralize(years, 'year');
  }
  if (elapsed.inDays > 30) {
    var months = elapsed.inDays ~/ 30;
    return pluralize(months, 'month');
  }
  if (elapsed.inDays > 1) {
    return pluralize(elapsed.inDays, 'day');
  }
  if (elapsed.inHours > 1) {
    return pluralize(elapsed.inHours, 'hour');
  }
  if (elapsed.inMinutes > JUST_NOW_LIMIT) {
    return '${elapsed.inMinutes} hours ago';
  } else {
    return 'just now';
  }
}