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
const String REPO_ROOT = 'https://github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}';
const String REPO_COMMIT_URL_ROOT = '${REPO_ROOT}/commit/';

//TODO: missing styling

@CustomTag('talaria-comments')
class TalariaComments extends PolymerElement {
  String path;
  
  @published String permalink;
  @published bool hide_comments = true;
  @published String comment_count;
  @published String blame_path;
  @published List comments = [];
  @published String newest_commit_url;
  
  @observable bool error = false;
  
  TalariaComments.created() : super.created() {}
  
  @override
  void enteredView() {
    super.enteredView();
    path = extrapolatePathFromPermalink(permalink);
    blame_path = '${REPO_ROOT}/blame/master/${path}';

    if (!window.sessionStorage.containsKey(path)) {
      _retrieveCommitData(path);  
    } else {
      // TODO for some reason this doesn't work as I expect it to, move it into another lifecycle callback?
      comments = JSON.decode(window.sessionStorage[path]).map((comment) => Comment.fromJson(comment));
    }
    hide_comments=true;
  }
  
  void expand(Event e, var detail, Node target){
    hide_comments = false;
  }
  
  void _updateCommentCount() {
    // once dart polymer supports the ternary operator, this can all be done inside the template
    comment_count = comments.length == 0 ? 'Be the first to comment' : '${comments.length} comment' + (comments.length > 1 ? 's' : '');
  }

  void _retrieveCommitData(resourcePath){
    HttpRequest.request('${COMMIT_API_ENDPOINT}?path=${resourcePath}', method: 'get', 
        requestHeaders: {'Accept':'application/vnd.github.v3.text+json' }).then(_retrieveComments).catchError(_handleErrors);
  }
  
  void _retrieveComments(HttpRequest apiResponse) {
    List commits = JSON.decode(apiResponse.response);
    newest_commit_url = '${REPO_COMMIT_URL_ROOT}${commits.first["sha"]}';
    Future.wait(commits.map(_retrieveCommitComments)).then(_handleComments).catchError(_handleErrors);
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
    _updateCommentCount();
  }
  
  void _handleErrors(HttpRequest error) {
    this.error = true;
    switch (error.status) {
      case 403:
        print("X-Rate Exceeded");
        break;
      default:
        print("An error occured.");
    }
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
  var days = elapsed.inDays;
  var years = elapsed.inDays ~/ 365;
  var months = elapsed.inDays ~/ 30;
  
  if (elapsed.inDays > 330) { // anything > 11 months = years
    var years = elapsed.inDays ~/ 365;
    return pluralize(years == 0 ? 1 : years, 'year');
  }
  if (elapsed.inDays > 25) { // anything > 25 days = months 
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
    return '${elapsed.inMinutes} minutes ago';
  } else {
    return 'just now';
  }
}