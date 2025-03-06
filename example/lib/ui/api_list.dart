// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_example/custom_token_manager.dart';
import 'package:kakao_flutter_sdk_example/message_template.dart';
import 'package:kakao_flutter_sdk_example/model/api_item.dart';
import 'package:kakao_flutter_sdk_example/model/picker_item.dart';
import 'package:kakao_flutter_sdk_example/ui/friend_page.dart';
import 'package:kakao_flutter_sdk_example/ui/parameter_dialog/login/login_dialog.dart';
import 'package:kakao_flutter_sdk_example/ui/parameter_dialog/login/login_parameter.dart';
import 'package:kakao_flutter_sdk_example/ui/parameter_dialog/talk/talk_api_dialog.dart';
import 'package:kakao_flutter_sdk_example/ui/parameter_dialog/talk/talk_api_parameter.dart';
import 'package:kakao_flutter_sdk_example/ui/parameter_dialog/user/user_api_dialog.dart';
import 'package:kakao_flutter_sdk_example/ui/parameter_dialog/user/user_api_parameter.dart';
import 'package:kakao_flutter_sdk_example/util/log.dart';
import 'package:path_provider/path_provider.dart';

const String tag = "KakaoSdkSample";

class ApiList extends StatefulWidget {
  final Map<String, dynamic> customData;

  const ApiList({super.key, required this.customData});

  @override
  ApiListState createState() => ApiListState();
}

class ApiListState extends State<ApiList> {
  final List<ApiItem> apiList = [];
  final Color plusColor = Colors.black12;
  Function(Friends?, Object?)? recursiveAppFriendsCompletion;

  @override
  void initState() {
    super.initState();
    _initApiList(widget.customData);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        itemBuilder: (context, index) {
          ApiItem item = apiList[index];
          bool isHeader = item.api == null;
          return ListTile(
            dense: isHeader,
            tileColor: item.backgroundColor,
            title: Text(
              item.label,
              style: TextStyle(
                  color:
                      isHeader ? Theme.of(context).primaryColor : Colors.black),
            ),
            onTap: apiList[index].api,
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1.0),
        itemCount: apiList.length);
  }

  _initApiList(Map<String, dynamic> customData) {
    apiList.addAll([
      ApiItem('User API'),
      ApiItem('isKakaoTalkInstalled()', api: () async {
        // 카카오톡 설치여부 확인

        bool result = await isKakaoTalkInstalled();
        String msg = result ? '카카오톡으로 로그인 가능' : '카카오톡 미설치: 카카오계정으로 로그인 사용 권장';
        Log.i(context, tag, msg);
      }),
      ApiItem('+loginWithKakaoTalk()', backgroundColor: plusColor,
          api: () async {
        LoginParameter? parameters = await showDialog(
          context: context,
          builder: (context) => LoginDialog('loginWithKakaoTalk'),
        );

        if (parameters == null) return;

        // 카카오톡으로 로그인

        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoTalk(
            nonce: parameters.nonce,
            channelPublicIds: parameters.channelPublicIds,
            serviceTerms: parameters.serviceTerms,
          );
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('+loginWithKakaoAccount()', backgroundColor: plusColor,
          api: () async {
        LoginParameter? parameters = await showDialog(
          context: context,
          builder: (context) => LoginDialog('loginWithKakaoAccount'),
        );

        if (parameters == null) return;

        // 카카오계정으로 로그인
        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount(
            prompts: parameters.prompts,
            loginHint: parameters.loginHint,
            channelPublicIds: parameters.channelPublicIds,
            serviceTerms: parameters.serviceTerms,
            nonce: parameters.nonce,
          );
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('+loginWithNewScopes()', backgroundColor: plusColor,
          api: () async {
        LoginParameter? parameters = await showDialog(
          context: context,
          builder: (context) => LoginDialog('loginWithNewScopes'),
        );

        if (parameters == null) return;

        // 새로운 동의항목으로 로그인

        try {
          OAuthToken token = await UserApi.instance.loginWithNewScopes(
            parameters.scopes,
            nonce: parameters.nonce,
          );
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('loginWithKakaoTalk()', api: () async {
        // 카카오톡으로 로그인

        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('loginWithKakaoAccount()', api: () async {
        // 카카오계정으로 로그인

        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('loginWithKakaoAccount(prompts:login)', api: () async {
        // 카카오계정으로 로그인 - 재인증

        try {
          OAuthToken token = await UserApi.instance
              .loginWithKakaoAccount(prompts: [Prompt.login]);
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('Combination Login', api: () async {
        // 로그인 조합 예제

        bool talkInstalled = await isKakaoTalkInstalled();

        // 카카오톡이 설치되어 있으면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
        if (talkInstalled) {
          try {
            OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
            Log.i(context, tag, '카카오톡으로 로그인 성공 ${token.accessToken}');
          } catch (e) {
            Log.e(context, tag, '카카오톡으로 로그인 실패', e);

            // 유저에 의해서 카카오톡으로 로그인이 취소된 경우 카카오계정으로 로그인 생략 (ex 뒤로가기)
            if (e is PlatformException && e.code == 'CANCELED') {
              return;
            }

            // 카카오톡에 로그인이 안되어있는 경우 카카오계정으로 로그인
            try {
              OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
              Log.i(context, tag, '카카오계정으로 로그인 성공 ${token.accessToken}');
            } catch (e) {
              Log.e(context, tag, '카카오계정으로 로그인 실패', e);
            }
          }
        } else {
          try {
            OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
            Log.i(context, tag, '카카오계정으로 로그인 성공 ${token.accessToken}');
          } catch (e) {
            Log.e(context, tag, '카카오계정으로 로그인 실패', e);
          }
        }
      }),
      ApiItem('Combination Login (Verbose)', api: () async {
        // 로그인 조합 예제 + 상세한 에러처리 콜백
        try {
          bool talkInstalled = await isKakaoTalkInstalled();
          //   카카오톡이 설치되어 있으면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
          OAuthToken token = talkInstalled
              ? await UserApi.instance.loginWithKakaoTalk()
              : await UserApi.instance.loginWithKakaoAccount();
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } on KakaoClientException catch (e) {
          Log.e(context, tag, '클라이언트 에러', e);
        } on KakaoAuthException catch (e) {
          if (e.error == AuthErrorCause.accessDenied) {
            Log.e(context, tag, '취소됨 (동의 취소)', e);
          } else if (e.error == AuthErrorCause.misconfigured) {
            Log.e(
                context,
                tag,
                '개발자사이트 앱 설정에 키 해시 또는 번들 ID를 등록하세요. 현재 값: ${await KakaoSdk.origin}',
                e);
          } else {
            Log.e(context, tag, '기타 인증 에러', e);
          }
        } catch (e) {
          // 에러처리에 대한 개선사항이 필요하면 데브톡(https://devtalk.kakao.com)으로 문의해주세요.
          Log.e(context, tag, '기타 에러 (네트워크 장애 등..)', e);
        }
      }),
      ApiItem('+me()', backgroundColor: plusColor, api: () async {
        UserApiParameter? parameters = await showDialog(
            context: context, builder: (context) => UserApiDialog('me'));

        if (parameters == null) return;

        // 사용자 정보 요청 (기본)

        try {
          User user =
              await UserApi.instance.me(properties: parameters.properties);
          Log.i(
              context,
              tag,
              '사용자 정보 요청 성공'
              '\n회원번호: ${user.id}'
              '\n이메일: ${user.kakaoAccount?.email}'
              '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
              '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 요청 실패', e);
        }
      }),
      ApiItem('me()', api: () async {
        // 사용자 정보 요청 (기본)

        try {
          User user = await UserApi.instance.me();
          Log.i(
              context,
              tag,
              '사용자 정보 요청 성공'
              '\n회원번호: ${user.id}'
              '\n이메일: ${user.kakaoAccount?.email}'
              '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
              '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 요청 실패', e);
        }
      }),
      ApiItem('me() - new scopes', api: () async {
        // 사용자 정보 요청 (추가 동의)

        // 사용자가 로그인 시 제3자 정보제공에 동의하지 않은 개인정보 항목 중 어떤 정보가 반드시 필요한 시나리오에 진입한다면
        // 다음과 같이 추가 동의를 받고 해당 정보를 획득할 수 있습니다.

        //  * 주의: 선택 동의항목은 사용자가 거부하더라도 서비스 이용에 지장이 없어야 합니다.

        // 추가 권한 요청 시나리오 예제

        User user;
        try {
          user = await UserApi.instance.me();
          Log.i(
              context,
              tag,
              '사용자 정보 요청 성공'
              '\n회원번호: ${user.id}'
              '\n이메일: ${user.kakaoAccount?.email}'
              '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
              '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 요청 실패', e);
          return;
        }

        List<String> scopes = [];

        if (user.kakaoAccount?.emailNeedsAgreement == true) {
          scopes.add('account_email');
        }
        if (user.kakaoAccount?.birthdayNeedsAgreement == true) {
          scopes.add("birthday");
        }
        if (user.kakaoAccount?.birthyearNeedsAgreement == true) {
          scopes.add("birthyear");
        }
        if (user.kakaoAccount?.phoneNumberNeedsAgreement == true) {
          scopes.add("phone_number");
        }
        if (user.kakaoAccount?.profileNeedsAgreement == true) {
          scopes.add("profile");
        }
        if (user.kakaoAccount?.ageRangeNeedsAgreement == true) {
          scopes.add("age_range");
        }

        if (scopes.isNotEmpty) {
          Log.d(context, tag, '사용자에게 추가 동의를 받아야 합니다.');

          OAuthToken token;
          try {
            token = await UserApi.instance.loginWithNewScopes(scopes);
            Log.i(context, tag, 'allowed scopes: ${token.scopes}');
          } catch (e) {
            Log.e(context, tag, "사용자 추가 동의 실패", e);
            return;
          }

          // 사용자 정보 재요청
          try {
            User user = await UserApi.instance.me();
            Log.i(
                context,
                tag,
                '사용자 정보 요청 성공'
                '\n회원번호: ${user.id}'
                '\n이메일: ${user.kakaoAccount?.email}'
                '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
                '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
          } catch (e) {
            Log.e(context, tag, '사용자 정보 요청 실패', e);
          }
        }
      }),
      ApiItem('signup()', api: () async {
        try {
          await UserApi.instance.signup();
          Log.i(context, tag, 'signup 성공');
        } catch (e) {
          Log.e(context, tag, 'signup 실패', e);
        }
      }),
      ApiItem('accessTokenInfo()', api: () async {
        // 토큰 정보 보기

        try {
          AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
          Log.i(context, tag,
              '토큰 정보 보기 성공\n회원정보: ${tokenInfo.id}\n만료시간: ${tokenInfo.expiresIn} 초');
        } catch (e) {
          Log.e(context, tag, '동의 철회 실패', e);
        }
      }),
      ApiItem('updateProfile()', api: () async {
        // 사용자 정보 저장

        try {
          // 변경할 내용
          Map<String, String> properties = {'custom_key': "${DateTime.now()}"};
          await UserApi.instance.updateProfile(properties);
          Log.i(context, tag, '사용자 정보 저장 성공');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 저장 실패', e);
        }
      }),
      ApiItem('selectShippingAddress()', api: () async {
        // 배송지 피커 호출
        try {
          final addressId = await UserApi.instance.selectShippingAddress();
          Log.i(context, tag, '배송지 선택 성공 $addressId');
        } catch (e) {
          Log.e(context, tag, '배송지 선택 실패 $e');
        }
      }),
      ApiItem('shippingAddresses()', api: () async {
        // 배송지 조회 (추가 동의)

        UserShippingAddresses userShippingAddress;
        try {
          userShippingAddress = await UserApi.instance.shippingAddresses();
        } catch (e) {
          Log.e(context, tag, '배송지 조회 실패', e);
          return;
        }

        if (userShippingAddress.shippingAddresses != null) {
          Log.i(context, tag,
              '배송지 조회 성공\n회원번호: ${userShippingAddress.userId}\n배송지: \n${userShippingAddress.shippingAddresses?.join('\n')}');
        } else if (userShippingAddress.needsAgreement == false) {
          Log.e(context, tag,
              '사용자 계정에 배송지 없음. 꼭 필요하다면 동의항목 설정에서 수집 기능을 활성화 해보세요.');
        } else if (userShippingAddress.needsAgreement == true) {
          Log.d(context, tag, '사용자에게 배송지 제공 동의를 받아야 합니다.');

          List<String> scopes = ['shipping_address'];

          // 사용자에게 배송지 제공 동의 요청
          OAuthToken token;
          try {
            token = await UserApi.instance.loginWithNewScopes(scopes);
            Log.d(context, tag, 'allowed scopes: ${token.scopes}');
          } catch (e) {
            Log.e(context, tag, '배송지 제공 동의 실패', e);
          }

          try {
            UserShippingAddresses userShippingAddresses =
                await UserApi.instance.shippingAddresses();
            Log.i(context, tag,
                '배송지 조회 성공\n회원번호: ${userShippingAddresses.userId}\n${userShippingAddresses.shippingAddresses?.join('\n')}');
          } catch (e) {
            Log.e(context, tag, '배송지 조회 실패', e);
          }
        }
      }),
      ApiItem('+serviceTerms()', backgroundColor: plusColor, api: () async {
        UserApiParameter? parameters = await showDialog(
            context: context,
            builder: (context) => UserApiDialog('serviceTerms'));

        if (parameters == null) return;

        // 동의한 약관 확인하기

        try {
          UserServiceTerms userServiceTerms = await UserApi.instance
              .serviceTerms(tags: parameters.tags, result: parameters.result);
          Log.i(context, tag,
              '동의한 약관 확인하기 성공\n회원정보: ${userServiceTerms.id}\n동의한 약관: \n${userServiceTerms.serviceTerms?.join('\n')}');
        } catch (e) {
          Log.e(context, tag, '동의한 약관 확인하기 실패', e);
        }
      }),
      ApiItem('+revokeServiceTerms()', backgroundColor: plusColor,
          api: () async {
        UserApiParameter? parameters = await showDialog(
            context: context,
            builder: (context) => UserApiDialog('revokeServiceTerms'));

        if (parameters == null) return;

        // 약관 철회하기

        try {
          UserRevokedServiceTerms userRevokedServiceTerms = await UserApi
              .instance
              .revokeServiceTerms(tags: parameters.serviceTerms ?? []);
          Log.i(context, tag,
              '약관 철회하기 성공\n회원정보: ${userRevokedServiceTerms.id}\n철회한 약관: \n${userRevokedServiceTerms.revokedServiceTerms?.join('\n')}');
        } catch (e) {
          Log.e(context, tag, '약관 철회하기 실패', e);
        }
      }),
      ApiItem('+scopes()', backgroundColor: plusColor, api: () async {
        UserApiParameter? parameters = await showDialog(
            context: context, builder: (context) => UserApiDialog('scopes'));

        if (parameters == null) return;

        // 동의 항목 확인하기

        try {
          ScopeInfo scopeInfo =
              await UserApi.instance.scopes(scopes: parameters.scopes);
          Log.i(
              context, tag, '동의 정보 확인 성공\n현재 가지고 있는 동의 항목 ${scopeInfo.scopes}');
        } catch (e) {
          Log.e(context, tag, '동의 정보 확인 실패', e);
        }
      }),
      ApiItem('+revokeScopes()', backgroundColor: plusColor, api: () async {
        UserApiParameter? parameters = await showDialog(
            context: context,
            builder: (context) => UserApiDialog('revokeScopes'));

        if (parameters == null) return;

        try {
          ScopeInfo scopeInfo =
              await UserApi.instance.revokeScopes(scopes: parameters.scopes);
          Log.i(context, tag, '동의 철회 성공\n현재 가지고 있는 동의 항목 ${scopeInfo.scopes}');
        } catch (e) {
          Log.e(context, tag, '동의 철회 실패', e);
        }
      }),
      ApiItem('logout()', api: () async {
        // 로그아웃

        try {
          await UserApi.instance.logout();
          Log.i(context, tag, '로그아웃 성공. SDK에서 토큰 삭제 됨');
        } catch (e) {
          Log.e(context, tag, '로그아웃 실패. SDK에서 토큰 삭제 됨', e);
        }
      }),
      ApiItem('unlink()', api: () async {
        // 연결 끊기

        try {
          await UserApi.instance.unlink();
          Log.i(context, tag, '연결 끊기 성공. SDK에서 토큰 삭제 됨');
        } catch (e) {
          Log.e(context, tag, '연결 끊기 실패', e);
        }
      }),
      ApiItem('KakaoTalk API'),
      ApiItem('profile()', api: () async {
        // 카카오톡 프로필 받기

        try {
          TalkProfile profile = await TalkApi.instance.profile();
          Log.i(context, tag,
              '카카오톡 프로필 받기 성공\n닉네임: ${profile.nickname}\n프로필사진: ${profile.thumbnailUrl}\n국가코드: ${profile.countryISO}');
        } catch (e) {
          Log.e(context, tag, '카카오톡 프로필 받기 실패', e);
        }
      }),
      ApiItem('sendCustomMemo()', api: () async {
        // 커스텀 템플릿으로 나에게 보내기

        // 메시지 템플릿 아이디
        // * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
        int templateId = customData['customMessage']!;

        try {
          await TalkApi.instance.sendCustomMemo(templateId: templateId);
          Log.i(context, tag, '나에게 보내기 성공');
        } catch (e) {
          Log.e(context, tag, '나에게 보내기 실패', e);
        }
      }),
      ApiItem('sendDefaultMemo()', api: () async {
        // 디폴트 템플릿으로 나에게 보내기 - Feed

        try {
          await TalkApi.instance.sendDefaultMemo(defaultFeed);
          Log.i(context, tag, '나에게 보내기 성공');
        } catch (e) {
          Log.e(context, tag, '나에게 보내기 실패', e);
        }
      }),
      ApiItem('sendScrapMemo()', api: () async {
        // 스크랩 템플릿으로 나에게 보내기

        // 공유할 웹페이지 URL
        //  * 주의: 개발자사이트 Web 플랫폼 설정에 공유할 URL의 도메인이 등록되어 있어야 합니다.
        String url = 'https://developers.kakao.com';

        try {
          await TalkApi.instance.sendScrapMemo(url: url);
          Log.i(context, tag, '나에게 보내기 성공');
        } catch (e) {
          Log.e(context, tag, '나에게 보내기 실패', e);
        }
      }),
      ApiItem('+friends()', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
            context: context, builder: (context) => TalkApiDialog('friends'));

        if (parameters == null) return;

        // 카카오톡 친구 목록 받기 (기본)

        try {
          Friends friends = await TalkApi.instance.friends(
            offset: parameters.offset,
            limit: parameters.limit,
            order: parameters.order,
            friendOrder: parameters.friendOrder,
          );
          Log.i(context, tag,
              '카카오톡 친구 목록 받기 성공\n${friends.elements?.map((e) => e.profileNickname).join('\n')}');

          // 친구의 UUID 로 메시지 보내기 가능
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
        }
      }),
      ApiItem("friends(order:) - desc", api: () async {
        // 카카오톡 친구 목록 받기 (파라미터)

        try {
          // 내림차순으로 받기
          Friends friends = await TalkApi.instance.friends(order: Order.desc);
          Log.i(context, tag,
              '카카오톡 친구 목록 받기 성공\n${friends.elements?.map((e) => e.profileNickname).join('\n')}');

          // 친구의 UUID 로 메시지 보내기 가능
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
        }
      }),
      ApiItem('friends(context:) - recursive', api: () async {
        FriendsContext nextFriendsContext = FriendsContext(
          offset: 0,
          limit: 3,
          order: Order.desc,
        );

        recursiveAppFriendsCompletion = (friends, error) async {
          if (error == null) {
            if (friends != null) {
              try {
                if (friends.afterUrl == null) {
                  return;
                }

                nextFriendsContext =
                    FriendsContext.fromUrl(Uri.parse(friends.afterUrl!));
              } catch (e) {
                return;
              }
            }

            try {
              Friends friends =
                  await TalkApi.instance.friends(context: nextFriendsContext);
              Log.i(context, tag,
                  '카카오톡 친구 목록 받기 성공\n${friends.elements?.map((e) => e.profileNickname).join('\n')}');
              recursiveAppFriendsCompletion?.call(friends, null);
            } catch (e) {
              Log.e(context, tag, '카카오톡 친구 목록 받기 실패');
            }
          }
        };

        recursiveAppFriendsCompletion?.call(null, null);
      }),
      ApiItem('friends(context:) - FriendContext', api: () async {
        try {
          Friends friends = await TalkApi.instance.friends(
              context: FriendsContext(offset: 0, limit: 1, order: Order.desc));
          Log.i(context, tag,
              '카카오톡 친구 목록 받기 성공\n${friends.elements?.join('\n')}');
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
        }
      }),
      ApiItem('sendCustomMessage()', api: () async {
        // 커스텀 템플릿으로 친구에게 메시지 보내기

        // 카카오톡 친구 목록 받기
        Friends friends;
        try {
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스의 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // 메시지 템플릿 아이디
          // * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
          int templateId = customData['customMessage']!;

          // 메시지 보내기
          try {
            MessageSendResult result = await TalkApi.instance.sendCustomMessage(
              receiverUuids: receiverUuids,
              templateId: templateId,
            );
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('sendDefaultMessage()', api: () async {
        // 디폴트 템플릿으로 친구에게 메시지 보내기 - Feed

        // 카카오톡 친구 목록 받기
        Friends friends;
        try {
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스의 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // Feed 메시지
          FeedTemplate template = defaultFeed;

          // 메시지 보내기
          try {
            MessageSendResult result =
                await TalkApi.instance.sendDefaultMessage(
              receiverUuids: receiverUuids,
              template: template,
            );
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('sendDefaultMessage() - calendar', api: () async {
        // 디폴트 템플릿으로 친구에게 메시지 보내기 - calendar

        // 카카오톡 친구 목록 받기
        Friends friends;
        try {
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스의 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // Calendar 메시지
          CalendarTemplate template =
              getDefaultCalendar(customData['calendarEventId']);

          // 메시지 보내기
          try {
            MessageSendResult result =
                await TalkApi.instance.sendDefaultMessage(
              receiverUuids: receiverUuids,
              template: template,
            );
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('sendScrapMessage()', api: () async {
        // 스크랩 템플릿으로 친구에게 메시지 보내기

        // 카카오톡 친구 목록 받기
        Friends friends;
        try {
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스의 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // 공유할 웹페이지 URL
          //  * 주의: 개발자사이트 Web 플랫폼 설정에 공유할 URL의 도메인이 등록되어 있어야 합니다.
          String url = "https://developers.kakao.com";

          // 메시지 보내기
          try {
            MessageSendResult result = await TalkApi.instance.sendScrapMessage(
              receiverUuids: receiverUuids,
              url: url,
            );
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('+channels()', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
            context: context, builder: (context) => TalkApiDialog('channels'));

        if (parameters == null) return;

        // 카카오톡 채널 관계 확인하기

        try {
          Channels relations =
              await TalkApi.instance.channels(parameters.publicIds);
          Log.i(context, tag, '채널 관계 확인 성공\n${relations.channels}');
        } catch (e) {
          Log.e(context, tag, '채널 관계 확인 실패', e);
        }
      }),
      ApiItem('+followChannel', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
          context: context,
          builder: (context) => TalkApiDialog(
            'followChannel',
            publicIds: customData['channelId'],
          ),
        );

        if (parameters == null) return;

        try {
          var result =
              await TalkApi.instance.followChannel(parameters.channelPublicId);
          Log.i(context, tag, '채널 추가 성공 $result');
        } catch (e) {
          Log.e(context, tag, '채널 추가 실패', e);
        }
      }),
      ApiItem('+addChannel()', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
          context: context,
          builder: (context) => TalkApiDialog(
            'addChannel',
            publicIds: customData['channelId'],
          ),
        );

        if (parameters == null) return;

        String channelId = parameters.channelPublicId;

        try {
          // 카카오톡 채널 추가하기
          await TalkApi.instance.addChannel(channelId);
        } catch (e) {
          Log.e(context, tag, '채널 추가 실패', e);
        }
      }),
      ApiItem('+chatChannel()', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
          context: context,
          builder: (context) => TalkApiDialog(
            'channelChat',
            publicIds: customData['channelId'],
          ),
        );

        if (parameters == null) return;

        String channelId = parameters.channelPublicId;

        try {
          // 카카오톡 채널 채팅하기
          await TalkApi.instance.chatChannel(channelId);
        } catch (e) {
          Log.e(context, tag, '채널 채팅 실패', e);
        }
      }),
      ApiItem('+addChannelUrl()', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
          context: context,
          builder: (context) => TalkApiDialog(
            'addChannelUrl',
            publicIds: customData['channelId'],
          ),
        );

        if (parameters == null) return;

        // 카카오톡 채널 추가하기 URL
        String channelId = parameters.channelPublicId;
        Uri url = await TalkApi.instance.addChannelUrl(channelId);

        // 디바이스 브라우저 열기
        try {
          await launchBrowserTab(url, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 채널 추가 실패', e);
        }
      }),
      ApiItem('+channelChatUrl()', backgroundColor: plusColor, api: () async {
        TalkApiParameter? parameters = await showDialog(
          context: context,
          builder: (context) => TalkApiDialog(
            'channelChatUrl',
            publicIds: customData['channelId'],
          ),
        );

        if (parameters == null) return;

        // 카카오톡 채널 채팅 URL
        String channelId = parameters.channelPublicId;
        Uri url = await TalkApi.instance.chatChannelUrl(channelId);

        // 디바이스 브라우저 열기
        try {
          await launchBrowserTab(url, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 채널 채팅 실패', e);
        }
      }),
      ApiItem('Friend API'),
      ApiItem('Picker Page',
          api: () => Navigator.pushNamed(context, '/picker')),
      ApiItem('KakaoTalk Sharing API'),
      ApiItem('isKakaoTalkSharingAvailable()', api: () async {
        // 카카오톡 설치여부 확인
        bool result = await ShareClient.instance.isKakaoTalkSharingAvailable();
        if (result) {
          Log.i(context, tag, '카카오톡 공유 가능');
        } else {
          Log.i(context, tag, '카카오톡 미설치: 웹 공유 사용 권장');
        }
      }),
      ApiItem('customTemplate()', api: () async {
        // 커스텀 템플릿으로 카카오톡 공유하기
        //  * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
        int templateId = customData['customMemo']!;

        try {
          Uri uri =
              await ShareClient.instance.shareCustom(templateId: templateId);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('scrapTemplate()', api: () async {
        // 스크랩 템플릿으로 카카오톡 공유하기

        // 공유할 웹페이지 URL
        // * 주의: 개발자사이트 Web 플랫폼 설정에 공유할 URL의 도메인이 등록되어 있어야 합니다.
        String url = "https://developers.kakao.com";

        try {
          Uri uri = await ShareClient.instance.shareScrap(url: url);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplate() - feed', api: () async {
        // 디폴트 템플릿으로 카카오톡 공유하기 - Feed

        try {
          Uri uri =
              await ShareClient.instance.shareDefault(template: defaultFeed);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplate() - list', api: () async {
        // 디폴트 템플릿으로 카카오톡 공유하기 - List

        try {
          Uri uri =
              await ShareClient.instance.shareDefault(template: defaultList);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplate() - location', api: () async {
        // 디폴트 템플릿으로 카카오톡 공유하기 - Location

        try {
          Uri uri = await ShareClient.instance
              .shareDefault(template: defaultLocation);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplate() - commerce', api: () async {
        // 디폴트 템플릿으로 카카오톡 공유하기 - Commerce

        try {
          Uri uri = await ShareClient.instance
              .shareDefault(template: defaultCommerce);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplate() - text', api: () async {
        // 디폴트 템플릿으로 카카오톡 공유하기 - Text

        try {
          Uri uri =
              await ShareClient.instance.shareDefault(template: defaultText);
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplate() - calendar', api: () async {
        // 디폴트 템플릿으로 카카오톡 공유하기 - Calendar

        try {
          Uri uri = await ShareClient.instance.shareDefault(
              template: getDefaultCalendar(customData['calendarEventId']));
          await ShareClient.instance.launchKakaoTalk(uri);
          Log.d(context, tag, '카카오톡 공유 성공');
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('customTemplateUri() - web sharer', api: () async {
        // 커스텀 템플릿으로 웹에서 카카오톡 공유하기

        // 메시지 템플릿 아이디
        // * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
        int templateId = customData['customMemo']!;

        try {
          Uri shareUrl = await WebSharerClient.instance.makeCustomUrl(
              templateId: templateId, templateArgs: {'key1': 'value1'});
          await launchBrowserTab(shareUrl, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('scrapTemplateUri() - web sharer', api: () async {
        // 스크랩 템플릿으로 웹에서 카카오톡 공유하기

        // 공유할 웹페이지 URL
        // * 주의: 개발자사이트 Web 플랫폼 설정에 공유할 URL의 도메인이 등록되어 있어야 합니다.
        String url = "https://developers.kakao.com";

        try {
          Uri shareUrl = await WebSharerClient.instance
              .makeScrapUrl(url: url, templateArgs: {'key1': 'value1'});
          await launchBrowserTab(shareUrl, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplateUri() - web sharer - feed', api: () async {
        // 커스텀 템플릿으로 웹에서 카카오톡 공유하기 - Feed

        try {
          Uri shareUrl = await WebSharerClient.instance
              .makeDefaultUrl(template: defaultFeed);
          await launchBrowserTab(shareUrl, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplateUri() - web sharer - location', api: () async {
        // 커스텀 템플릿으로 웹에서 카카오톡 공유하기 - Location

        try {
          Uri shareUrl = await WebSharerClient.instance
              .makeDefaultUrl(template: defaultLocation);
          await launchBrowserTab(shareUrl, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('defaultTemplateUri() - web sharer - calendar', api: () async {
        // 커스텀 템플릿으로 웹에서 카카오톡 공유하기 - Feed

        try {
          Uri shareUrl = await WebSharerClient.instance.makeDefaultUrl(
              template: getDefaultCalendar(customData['calendarEventId']));
          await launchBrowserTab(shareUrl, popupOpen: kIsWeb);
        } catch (e) {
          Log.e(context, tag, '카카오톡 공유 실패', e);
        }
      }),
      ApiItem('uploadImage() - File', api: () async {
        // 이미지 업로드

        // 로컬 이미지 파일
        // 이 샘플에서는 프로젝트 리소스로 추가한 이미지 파일을 사용했습니다. 갤러리 등 서비스 니즈에 맞는 사진 파일을 준비하세요.
        ByteData byteData = await rootBundle.load('assets/images/cat1.png');

        // 이 샘플에서는 path_provider를 사용해 프로젝트 리소스를 이미지 파일로 저장했습니다.
        File tempFile =
            File('${(await getTemporaryDirectory()).path}/cat1.png');
        File file = await tempFile.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

        try {
          // 카카오 이미지 서버로 업로드
          ImageUploadResult imageUploadResult =
              await ShareClient.instance.uploadImage(image: file);
          Log.i(
              context, tag, '이미지 업로드 성공\n${imageUploadResult.infos.original}');
        } catch (e) {
          Log.e(context, tag, '이미지 업로드 실패', e);
        }
      }),
      ApiItem('uploadImage() - ByteData', api: () async {
        // 이미지 업로드

        // 이 샘플에서는 file_picker를 사용해 이미지 파일을 가져왔습니다.
        var filePickerResult =
            await FilePicker.platform.pickFiles(withData: true);

        if (filePickerResult != null) {
          var byteData = filePickerResult.files.first.bytes;

          try {
            // 카카오 이미지 서버로 업로드
            ImageUploadResult imageUploadResult =
                await ShareClient.instance.uploadImage(byteData: byteData);
            Log.i(context, tag,
                '이미지 업로드 성공\n${imageUploadResult.infos.original}');
          } catch (e) {
            Log.e(context, tag, '이미지 업로드 실패', e);
          }
        }
      }),
      ApiItem('scrapImage()', api: () async {
        // 이미지 스크랩

        // 원본 원격 이미지 URL
        String url =
            'https://t1.kakaocdn.net/kakaocorp/Service/KakaoTalk/pc/slide/talkpc_theme_01.jpg';

        try {
          // 카카오 이미지 서버로 업로드
          ImageUploadResult imageUploadResult =
              await ShareClient.instance.scrapImage(imageUrl: url);
          Log.i(
              context, tag, '이미지 스크랩 성공\n${imageUploadResult.infos.original}');
        } catch (e) {
          Log.e(context, tag, '이미지 스크랩 실패', e);
        }
      }),
      ApiItem('KakaoNavi API'),
      ApiItem('isKakaoNaviInstalled()', api: () async {
        // 카카오내비 설치여부 확인
        bool result = await NaviApi.instance.isKakaoNaviInstalled();
        if (result) {
          Log.i(context, tag, '카카오내비 앱으로 길안내 가능');
        } else {
          Log.i(context, tag, '카카오내비 미설치');
        }
      }),
      ApiItem('shareDestination - KATEC', api: () async {
        if (await NaviApi.instance.isKakaoNaviInstalled()) {
          // 카카오내비 앱으로 목적지 공유하기 - KATEC
          await NaviApi.instance.shareDestination(
            destination: Location(name: '카카오 판교오피스', x: '321286', y: '533707'),
          );
        } else {
          // 카카오내비 설치 페이지로 이동
          launchBrowserTab(Uri.parse(NaviApi.webNaviInstall),
              popupOpen: kIsWeb);
        }
      }),
      ApiItem('shareDestination - WGS84', api: () async {
        if (await NaviApi.instance.isKakaoNaviInstalled()) {
          // 카카오내비 앱으로 목적지 공유하기 - WGS84
          await NaviApi.instance.shareDestination(
            destination:
                Location(name: '카카오 판교오피스', x: '127.108640', y: '37.402111'),
            option: NaviOption(coordType: CoordType.wgs84),
          );
        } else {
          // 카카오내비 설치 페이지로 이동
          launchBrowserTab(Uri.parse(NaviApi.webNaviInstall),
              popupOpen: kIsWeb);
        }
      }),
      ApiItem('navigate - KATEC - viaList', api: () async {
        if (await NaviApi.instance.isKakaoNaviInstalled()) {
          // 카카오내비 앱으로 목적지 공유하기 - KATEC - 경유지 추가
          await NaviApi.instance.navigate(
            destination: Location(name: '카카오 판교오피스', x: '321286', y: '533707'),
            viaList: [
              Location(name: '판교역 1번출구', x: '321525', y: '532951'),
            ],
          );
        } else {
          // 카카오내비 설치 페이지로 이동
          launchBrowserTab(Uri.parse(NaviApi.webNaviInstall),
              popupOpen: kIsWeb);
        }
      }),
      ApiItem('navigate - WGS84 - viaList', api: () async {
        if (await NaviApi.instance.isKakaoNaviInstalled()) {
          // 카카오내비 앱으로 목적지 공유하기 - WGS84 - 경유지 추가
          await NaviApi.instance.navigate(
            destination:
                Location(name: '카카오 판교오피스', x: '127.108640', y: '37.402111'),
            viaList: [
              Location(name: '판교역 1번출구', x: '127.111492', y: '37.395225'),
            ],
            option: NaviOption(coordType: CoordType.wgs84),
          );
        } else {
          // 카카오내비 설치 페이지로 이동
          launchBrowserTab(Uri.parse(NaviApi.webNaviInstall),
              popupOpen: kIsWeb);
        }
      }),
      ApiItem('Kakao Sync'),
      ApiItem('login(serviceTerms:) - select one', api: () async {
        // 약관 선택해 동의 받기

        // 개발자사이트 간편가입 설정에 등록한 약관 목록 중, 동의 받기를 원하는 약관의 태그 값을 지정합니다.
        List<String> serviceTerms = ['service'];

        try {
          OAuthToken token = await UserApi.instance
              .loginWithKakaoTalk(serviceTerms: serviceTerms);
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('login(serviceTerms:) - empty', api: () async {
        // 약관 동의 받지 않기

        try {
          // serviceTerms 파라미터에 empty list 전달해서 카카오톡으로 로그인 요청 (카카오계정으로 로그인도 사용법 동일)
          OAuthToken token =
              await UserApi.instance.loginWithKakaoTalk(serviceTerms: []);
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('OIDC'),
      ApiItem('loginWithKakaoTalk(nonce:openidtest)', api: () async {
        // 카카오톡으로 로그인 - openId

        try {
          OAuthToken token =
              await UserApi.instance.loginWithKakaoTalk(nonce: 'openidtest');
          Log.i(context, tag, '로그인 성공 idToken: ${token.idToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('loginWithKakaoAccount(nonce:openidtest)', api: () async {
        // 카카오계정으로 로그인 - openId

        try {
          OAuthToken token =
              await UserApi.instance.loginWithKakaoAccount(nonce: 'openidtest');
          Log.i(context, tag, '로그인 성공 idToken: ${token.idToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('me() - new scopes(nonce:openidtest)', api: () async {
        // 사용자 정보 요청 (추가 동의)

        // 사용자가 로그인 시 제3자 정보제공에 동의하지 않은 개인정보 항목 중 어떤 정보가 반드시 필요한 시나리오에 진입한다면
        // 다음과 같이 추가 동의를 받고 해당 정보를 획득할 수 있습니다.

        //  * 주의: 선택 동의항목은 사용자가 거부하더라도 서비스 이용에 지장이 없어야 합니다.

        // 추가 권한 요청 시나리오 예제

        User user;
        try {
          user = await UserApi.instance.me();
          Log.i(
              context,
              tag,
              '사용자 정보 요청 성공'
              '\n회원번호: ${user.id}'
              '\n이메일: ${user.kakaoAccount?.email}'
              '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
              '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 요청 실패', e);
          return;
        }

        List<String> scopes = [];

        if (user.kakaoAccount?.emailNeedsAgreement == true) {
          scopes.add('account_email');
        }
        if (user.kakaoAccount?.birthdayNeedsAgreement == true) {
          scopes.add("birthday");
        }
        if (user.kakaoAccount?.birthyearNeedsAgreement == true) {
          scopes.add("birthyear");
        }
        if (user.kakaoAccount?.phoneNumberNeedsAgreement == true) {
          scopes.add("phone_number");
        }
        if (user.kakaoAccount?.profileNeedsAgreement == true) {
          scopes.add("profile");
        }
        if (user.kakaoAccount?.ageRangeNeedsAgreement == true) {
          scopes.add("age_range");
        }

        if (scopes.isNotEmpty) {
          Log.d(context, tag, '사용자에게 추가 동의를 받아야 합니다.');

          // OpenID 활성화 후
          // - scope 파라메터에 openid 항목을 포함하여 요청할 경우 OIDC로 동작
          // - scope 파라메터에 openid 항목을 미포함 시 OAuth2.0 으로 동작

          // OIDC 요청이므로 "openid" 항목을 추가한다
          scopes.add('openid');

          OAuthToken token;
          try {
            token = await UserApi.instance
                .loginWithNewScopes(scopes, nonce: 'openidtest');
            Log.i(context, tag, 'allowed scopes: ${token.scopes}');
          } catch (e) {
            Log.e(context, tag, "사용자 추가 동의 실패", e);
            return;
          }

          // 사용자 정보 재요청
          try {
            User user = await UserApi.instance.me();
            Log.i(
                context,
                tag,
                '사용자 정보 요청 성공'
                '\n회원번호: ${user.id}'
                '\n이메일: ${user.kakaoAccount?.email}'
                '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
                '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
          } catch (e) {
            Log.e(context, tag, '사용자 정보 요청 실패', e);
          }
        }
      }),
      ApiItem('ETC'),
      ApiItem('Get Current Token', api: () async {
        // 현재 토큰 저장소에서 토큰 가져오기
        Log.i(context, tag,
            '${await TokenManagerProvider.instance.manager.getToken()}');
      }),
      ApiItem('Set Custom TokenManager', api: () async {
        // 커스텀 토큰 저장소 설정
        TokenManagerProvider.instance.manager = CustomTokenManager();
        Log.i(context, tag, '커스텀 토큰 저장소 사용');
      }),
      ApiItem('Set Default TokenManager', api: () async {
        // 기본 저장소 재설정
        TokenManagerProvider.instance.manager = DefaultTokenManager();
        Log.i(context, tag, '기본 토큰 저장소 설정');
      }),
      ApiItem('hasToken() usage', api: () async {
        if (await AuthApi.instance.hasToken()) {
          try {
            AccessTokenInfo tokenInfo =
                await UserApi.instance.accessTokenInfo();
            Log.i(context, tag,
                '토큰 유효성 체크 성공 ${tokenInfo.id} ${tokenInfo.expiresIn}');
          } catch (e) {
            if (e is KakaoException && e.isInvalidTokenError()) {
              Log.e(context, tag, '토큰이 만료되었습니다.', e);
            } else {
              Log.e(context, tag, '토큰 정보를 가져오는데 실패했습니다', e);
            }

            try {
              // 카카오 계정으로 로그인
              OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
              Log.i(context, tag, '로그인 성공 ${token.accessToken}');
            } catch (e) {
              Log.e(context, tag, '로그인 실패', e);
            }
          }
        } else {
          Log.i(context, tag, '토큰이 없습니다.');
          try {
            OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
            Log.i(context, tag, '로그인 성공 ${token.accessToken}');
          } catch (e) {
            Log.e(context, tag, '로그인 실패', e);
          }
        }
      }),
    ]);
  }
}
